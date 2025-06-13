import sys
from pprint import pprint
from subprocess import CalledProcessError
from os import path as osp
from textwrap import dedent

from pytest_infrahouse import terraform_apply

from tests.conftest import TRACE_TERRAFORM, LOG


def test_state_bucket(
    keep_after,
    aws_region,
    test_role_arn,
):
    terraform_module_dir = "test_data/state-bucket"
    try:
        with open(osp.join(terraform_module_dir, "terraform.tfvars"), "w") as fp:
            fp.write(
                dedent(
                    f"""
                    region = "{aws_region}"
                    """
                )
            )
            if test_role_arn:
                fp.write(
                    dedent(
                        f"""
                        role_arn = "{test_role_arn}"
                        """
                    )
                )
        with terraform_apply(
            terraform_module_dir,
            destroy_after=not keep_after,
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
