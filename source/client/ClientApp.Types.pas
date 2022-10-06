unit ClientApp.Types;

interface

uses
  System.Generics.Collections,
  System.Rtti,

  Fido.EventsDriven.Broker.PubSub.Intf,
  Fido.Memory.EventsDriven.Broker.PubSub,
  Fido.EventsDriven.Producer.Intf,
  Fido.Memory.EventsDriven.Producer.PubSub,
  Fido.EventsDriven.Consumer.PubSub.Intf,
  Fido.Memory.EventsDriven.Consumer.PubSub,
  Fido.EventsDriven.Listener.PubSub,
  Fido.EventsDriven.Publisher.Intf,
  Fido.EventsDriven.Publisher;

type
  TLoginViewAction = (Login, Signup);

  PayloadType = TArray<TValue>;

  IPubSubEventsDrivenBroker = IPubSubEventsDrivenBroker<PayloadType>;
  TMemoryPubSubEventsDrivenBroker = TMemoryPubSubEventsDrivenBroker<PayloadType>;
  IPubSubEventsDrivenConsumer = IPubSubEventsDrivenConsumer<PayloadType>;
  TMemoryPubSubEventsDrivenConsumer = TMemoryPubSubEventsDrivenConsumer<PayloadType>;
  IPubSubEventsDrivenConsumerFactory = IPubSubEventsDrivenConsumerFactory<PayloadType>;
  IEventsDrivenProducer = IEventsDrivenProducer<PayloadType>;
  TMemoryPubSubEventsDrivenProducer = TMemoryPubSubEventsDrivenProducer<PayloadType>;
  IEventsDrivenProducerFactory = IEventsDrivenProducerFactory<PayloadType>;
  TPubSubEventsDrivenListener = TPubSubEventsDrivenListener<PayloadType>;
  IEventsDrivenPublisher = IEventsDrivenPublisher<PayloadType>;
  TEventsDrivenPublisher = TEventsDrivenPublisher<PayloadType>;

implementation

end.
