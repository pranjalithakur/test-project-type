# Aptos smart contracts

A repository of smart contracts packages written in `move` for `Aptos` blockchain (`core-move`). In the future this repository might also contain `move` packages for the `Sui` blockchain (`sui-move`).

## Contents

- `aptos-staker`: `Aptos` liquid staking solution

## Linter for logic

### Move prover

1. Navigate to the directory containing your `cargo.toml` (and `aptos-cli` installation) and follow these steps: https://aptos.dev/tools/aptos-cli/install-cli/install-move-prover
2. Then run

```
aptos move prove --package-dir aptos-staker --dev
```

or inside your package run:
```
aptos move prove --named-addresses publisher=default
```
or `aptos move prove --dev` to find security issues in your move software. The `Prover.toml` contains the standard settings for the `move prover`.

## Initialising a new project:

Initialise a new Aptos move package by creating a new directory `mkdir new-move-package-name` and initialising the new aptos move package inside the folder using: 

`aptos move init --name ${new-move-package-name}`

## Compiling a project


Compile a **development version** of your project using `dev-addresses` and `dev_dependencies` specified inside `Move.toml`:

`aptos move compile --dev`


Compile a **production version** of this project using `addresses` and `dependencies` specified inside `Move.toml`: `aptos move compile --named-addresses publisher=0xC0FFEE`


## Testing a project

To test a **development version** of the package _from within the package folder_ without worrying about deployment addresses run:

`aptos move test --dev`


To test a *development version* of the `aptos-staker` package _from the root folder_ run:
`aptos move test --package-dir aptos-staker --dev`

If you have your publishers set:
to test a *production version* of the project _from within its folder_ run: `aptos move test`

To test a *production version* of the `aptos-staker` package _from the root folder_ run:
`aptos move test --package-dir aptos-staker`

To test the *testnet staker*:
1. cd into aptos-staker
2. `aptos move compile --named-addresses default_admin=default_admin,src_account=src_account,publisher=<staker_address>`
3. Run the following, replacing test.mv with the desired test file and script_acc with your aptos profile: 
`aptos move run-script --compiled-script-path build/aptos-staker/bytecode_scripts/test.mv --profile script_acc`

Add  `--profile-gas > test_logs.txt` to print debug statements and only simulate the tests without actually executing them. Note that to simulate i.e unlock tests you will first need to run the stake tests. 

**Test coverage**

To obtain the test coverage simply add `--coverage`.
Inside aptos-staker run:
`aptos move test --dev --coverage`

This will create the file `.coverage_map.mvcov` that is used to show gaps in test coverage running:
`aptos move coverage source --dev --module staker`

