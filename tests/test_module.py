from pprint import pprint
from os import path as osp
from textwrap import dedent
import os
import shutil

import pytest
from pytest_infrahouse import terraform_apply


def _prepare_fixture(
    terraform_module_dir: str,
    aws_provider_version: str,
    aws_region: str,
    test_role_arn: str,
    replication_region: str,
) -> None:
    for artifact_file in [".terraform.lock.hcl"]:
        state_path = osp.join(terraform_module_dir, artifact_file)
        try:
            os.remove(state_path)
        except FileNotFoundError:
            pass

    terraform_dir = osp.join(terraform_module_dir, ".terraform")
    try:
        shutil.rmtree(terraform_dir)
    except FileNotFoundError:
        pass

    with open(osp.join(terraform_module_dir, "terraform.tf"), "w") as fp:
        fp.write(
            dedent(
                f"""
                terraform {{
                  required_providers {{
                    aws = {{
                      source  = "hashicorp/aws"
                      version = "{aws_provider_version}"
                    }}
                  }}
                }}
                """
            )
        )

    with open(osp.join(terraform_module_dir, "terraform.tfvars"), "w") as fp:
        fp.write(
            dedent(
                f"""
                region             = "{aws_region}"
                replication_region = "{replication_region}"
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


@pytest.mark.parametrize("aws_provider_version", ["~> 6.0"])
def test_state_bucket(
    keep_after,
    aws_region,
    test_role_arn,
    aws_provider_version,
):
    terraform_module_dir = "test_data/state-bucket"
    replication_region = "us-east-1" if aws_region != "us-east-1" else "us-west-2"

    _prepare_fixture(
        terraform_module_dir,
        aws_provider_version=aws_provider_version,
        aws_region=aws_region,
        test_role_arn=test_role_arn,
        replication_region=replication_region,
    )

    with terraform_apply(
        terraform_module_dir,
        destroy_after=not keep_after,
        json_output=True,
    ) as tf_out:
        pprint(tf_out)
        assert tf_out["bucket_name"]["value"]
        assert tf_out["bucket_arn"]["value"]
        assert tf_out["lock_table_name"]["value"]
        assert tf_out["lock_table_arn"]["value"]
        assert tf_out["replica_bucket_name"]["value"].endswith("-replica")
        assert tf_out["replica_bucket_arn"]["value"]
