

# FidoDemoApp

FidoDemoApp is a never ending and always work in progress demo project/showcase that shows how to create backend (micro)services and MVVM frontend using the [FidoLib](https://github.com/mirko-bianco/FidoLib) library.

## Dependencies

The Fido library depends on the following open source libraries:

[Spring4D](https://bitbucket.org/sglienke/spring4d/src/master/)

[FidoLib](https://github.com/mirko-bianco/FidoLib)

## Installation

1) clone the source to a location of your choice
2) Create a system environment variable `FIDOAPP` pointing to the `fidoapp\source` folder
3) Go to Delphi menu -> Tools -> Options... -> Delphi Options  -> Library
4) add `$(FIDOAPP)\source\shared;$(FIDOAPP)\source\shared\Persistence\ApiClients;$(FIDOAPP)\source\shared\Persistence\Gateways;$(FIDOAPP)\source\shared\Persistence\Repositories;$(FIDOAPP)\source\shared\Presentation\Controllers\ApiServers;$(FIDOAPP)\source\shared\Domain;$(FIDOAPP)\source\shared\Domain\ClientTokensCache;$(FIDOAPP)\source\shared\Domain\UseCases` to the Library path (for all the available platforms.
