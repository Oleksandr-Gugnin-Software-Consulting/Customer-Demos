from setuptools import find_packages, setup

setup(
    name="customer-demos",
    version="0.0.0",
    packages=find_packages(exclude=("tests",)),
    include_package_data=True,
    description="Demo project for CI runner testing",
)
