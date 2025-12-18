#!/usr/bin/env python3

"""Minimal LibreLane flow to only run the seal ring generator on a GDS input."""

import os
import sys
import yaml
import argparse
from typing import List, Type

from librelane.steps import KLayout, Step
from librelane.flows.sequential import SequentialFlow
from librelane.flows.flow import FlowError


class SealRingFlow(SequentialFlow):
    """Sequential flow that only invokes the KLayout seal-ring step."""

    Steps: List[Type[Step]] = [KLayout.SealRing]


def main(config_path: str) -> None:
    """Run the seal-ring-only flow using the provided configuration file."""

    pdk_root = os.getenv("PDK_ROOT", os.path.expanduser("~/.ciel"))
    pdk = os.getenv("PDK", "gf180mcuD")

    print(f"PDK_ROOT = {pdk_root}")
    print(f"PDK = {pdk}")

    with open(config_path, "r", encoding="utf-8") as cfg_file:
        flow_cfg = yaml.safe_load(cfg_file)

    flow = SealRingFlow(
        flow_cfg,
        design_dir=os.path.dirname(config_path),
        pdk_root=pdk_root,
        pdk=pdk,
    )

    try:
        flow.start()
    except FlowError as err:
        print(f"Error:\n{err}")
        sys.exit(1)

    print("Seal-ring generation completed successfully.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run only the KLayout seal-ring step.")
    parser.add_argument("config", help="Path to the seal-ring config YAML (expects GDS input)")
    args = parser.parse_args()
    main(args.config)
