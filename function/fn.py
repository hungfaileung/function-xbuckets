"""A Crossplane composition function."""

import grpc
from crossplane.function import logging, response
from crossplane.function.proto.v1 import run_function_pb2 as fnv1
from crossplane.function.proto.v1 import run_function_pb2_grpc as grpcv1


class FunctionRunner(grpcv1.FunctionRunnerService):
    """A FunctionRunner handles gRPC RunFunctionRequests."""

    def __init__(self):
        """Create a new FunctionRunner."""
        self.log = logging.get_logger()

    async def RunFunction(
        self, req: fnv1.RunFunctionRequest, _: grpc.aio.ServicerContext
    ) -> fnv1.RunFunctionResponse:
        """Run the function."""
        # Create a logger for this request.
        log = self.log.bind(tag=req.meta.tag)
        log.info("Running function")

        # Create a response to the request. This copies the desired state and
        # pipeline context from the request to the response.
        rsp = response.to(req)

        # Get the region and a list of bucket names from the observed composite
        # resource (XR). Crossplane represents resources using the Struct
        # well-known protobuf type. The Struct Python object can be accessed
        # like a dictionary.
        region = req.observed.composite.resource["spec"]["region"]
        names = req.observed.composite.resource["spec"]["names"]

        # Add a desired S3 bucket for each name.
        for name in names:
            # Crossplane represents desired composed resources using a protobuf
            # map of messages. This works a little like a Python defaultdict.
            # Instead of assigning to a new key in the dict-like map, you access
            # the key and mutate its value as if it did exist.
            #
            # The below code works because accessing the xbuckets-{name} key
            # automatically creates a new, empty fnv1.Resource message. The
            # Resource message has a resource field containing an empty Struct
            # object that can be populated from a dictionary by calling update.
            #
            # https://protobuf.dev/reference/python/python-generated/#map-fields
            rsp.desired.resources[f"xbuckets-{name}"].resource.update(
                {
                    "apiVersion": "s3.aws.upbound.io/v1beta1",
                    "kind": "Bucket",
                    "metadata": {
                        "annotations": {
                            "crossplane.io/external-name": name,
                        },
                    },
                    "spec": {
                        "forProvider": {
                            "region": region,
                        },
                    },
                }
            )

        # Log what the function did. This will only appear in the function's pod
        # logs. A function can use response.normal() and response.warning() to
        # emit Kubernetes events associated with the XR it's operating on.
        log.info("Added desired buckets", region=region, count=len(names))

        return rsp