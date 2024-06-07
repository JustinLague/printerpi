from setuptools import setup, find_packages

setup(
    name='printerpi',
    version='0.0.1',
    packages=find_packages(),
    install_requires=[
        'redis',
    ],
     entry_points={
        'console_scripts': [
            'printerpi = bluetooth_light.__main__:main',
        ]
    }
)