#!/usr/bin/env python3

import yaml
import sys


required_fields = ["id", "name", "description", "tags", "playbook", "args"]


def main() -> None:
    """
    Validate the catalog.yml file for correct structure and required fields.
    """
    try:
        with open("catalog.yml", "r") as file:
            catalog = yaml.safe_load(file)

        if "images" not in catalog:
            print("Error: catalog.yml should contain an 'images' key.")
            sys.exit(1)

        # Check if catalog is a list
        if not isinstance(catalog["images"], list):
            print("Error: 'images' in catalog.yml should be a list of AMI entries.")
            sys.exit(1)

        # Validate each entry in the catalog
        for index, entry in enumerate(catalog["images"]):
            if not isinstance(entry, dict):
                print(f"Error: Entry {index} is not a dictionary.")
                sys.exit(1)

            for field in required_fields:
                if field not in entry:
                    print(
                        f"Error: Entry {index} is missing required field '{field}'.")
                    sys.exit(1)

        print("catalog.yml validation passed.")

    except FileNotFoundError:
        print("Error: catalog.yml file not found.")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error parsing catalog.yml: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
