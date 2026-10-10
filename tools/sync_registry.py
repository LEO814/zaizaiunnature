#!/usr/bin/env python3
from pathlib import Path
from project_layout import write_registry
if __name__ == "__main__":
    registry = write_registry(Path(__file__).resolve().parents[1])
    print("Registered", len(registry["entries"]), "planned package entries")
