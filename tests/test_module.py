from pprint import pprint
from os import path as osp
from textwrap import dedent
import os

import pytest
from pytest_infrahouse import terraform_apply


@pytest.mark.parametrize("aws_provider_version", ["~> 5.31", "~> 6.0"])
def test_state_bucket(
    keep_after,
    aws_region,
    test_role_arn,
    aws_provider_version,
):
    terraform_module_dir = "test_data/state-bucket"

    # Clean up any existing Terraform state files
    for artifact_file in [".terraform.lock.hcl"]:
        state_path = osp.join(terraform_module_dir, artifact_file)
        try:
            os.remove(state_path)
        except FileNotFoundError:
            pass

    # Remove .terraform directory if it exists
    terraform_dir = osp.join(terraform_module_dir, ".terraform")
    try:
        import shutil

        shutil.rmtree(terraform_dir)
    except FileNotFoundError:
        pass

    # Update terraform.tf with the specified AWS provider version
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
    ) as tf_out:
        pprint(tf_out)
