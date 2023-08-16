# Register Transformer DK

This is an application for ingesting DK records from a Kinesis stream (published by [register_ingester_dk](https://github.com/openownership/register-ingester-dk)) and transforming into [BODS v0.2](https://standard.openownership.org/en/0.2.0/) records. These records are then stored in Elasticsearch and optionally emitted into their own Kinesis stream.

## Installation

Install and boot [register-v2](https://github.com/openownership/register-v2).

Configure your environment using the example file:

```sh
cp .env.example .env
```

Create the Elasticsearch BODS index (configured by `BODS_INDEX`):

```sh
docker compose run transformer-dk setup_indexes
```

## Testing

Run the tests:

```sh
docker compose run transformer-dk test
```

## Usage

To run the local transformer:

```sh
docker compose run transformer-dk transform
```
