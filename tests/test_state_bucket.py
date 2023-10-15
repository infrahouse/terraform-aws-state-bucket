import sys
from pprint import pprint
from subprocess import CalledProcessError

from infrahouse_toolkit.terraform import terraform_apply

from tests.conftest import TRACE_TERRAFORM, TEST_ACCOUNT, LOG


def test_state_bucket(
    ec2_client_map,
):
    tf_dir = "test_data/state-bucket"
    try:
        with terraform_apply(
            tf_dir,
            json_output=True,
            enable_trace=TRACE_TERRAFORM,
        ) as tf_out:
            pprint(tf_out)
    except CalledProcessError as err:
        LOG.error(err)
        LOG.info("STDOUT: %s", err.stdout)
        LOG.error("STDERR: %s", err.stderr)
        if TRACE_TERRAFORM:
            LOG.info("Check output in files tf-apply-trace.txt, tf-destroy-trace.txt.")
        sys.exit(1)
