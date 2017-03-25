-module(create_customer_listener).
-include("amqp_client.hrl").
-compile(export_all).

start() ->
	io:format("hello world~n"),
	{ok, Connection} = amqp_connection:start(#amqp_params_network{}),
	{ok, Channel} = amqp_connection:open_channel(Connection),	
	%Declare = #'exchange.declare'{exchange = <<"customer_exchange">>},
	%#'exchange.declare_ok'{} = amqp_channel:call(Channel, Declare),
	%io:format("exchange declared~n"),
	{Connection, Channel}.

createQueue(QName, Channel) ->
	Queue = #'queue.declare'{queue = QName},
	#'queue.declare_ok'{} = amqp_channel:call(Channel, Queue),
	%#'queue.declare_ok'{queue = Queue}
		% = amqp_channel:call(Channel, #'queue.declare'{}),
	io:format("Queue ~p~n", [Queue]),
	%Binding = #'queue.bind'{queue = Queue,routing_key = Queue},
	%#'queue.bind_ok'{} = amqp_channel:call(Channel, Binding),
	Queue.

send(QName, Channel, Msg) ->
	Publish = #'basic.publish'{exchange = <<>>, routing_key = QName},
	amqp_channel:cast(Channel, Publish, #amqp_msg{payload = Msg}),
	Msg.

loop(Channel) ->
	receive
		#'basic.consume_ok'{} -> io:format("subscription ok~n"), 
															loop(Channel);

		#'basic.cancel_ok'{} -> io:format("sub. cancel ok~n"), ok;

		{#'basic.deliver'{delivery_tag = Tag}, Content} ->
											#amqp_msg{payload = Payload} = Content,
											io:format("rec. message: ~p~n", [Payload]),
											amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
											timer:sleep(333),
											loop(Channel)
		end.


subscribe(QName, Channel) ->
	Sub = #'basic.consume'{queue = QName},
	#'basic.consume_ok'{consumer_tag = Tag} = amqp_channel:subscribe(Channel, Sub, self()),
	loop(Channel).

poll(QName, Channel) ->
	io:format("polling for message~n"),
	
	%Get = #'basic.get'{queue = Queue, no_ack = true},
	Get = #'basic.get'{queue = QName},
	case amqp_channel:call(Channel, Get) of
		{#'basic.get_ok'{delivery_tag = Tag}, Content} -> io:format("Msg. received!~n"),
											#amqp_msg{payload = Payload} = Content,
											amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
											Payload;
		#'basic.get_empty'{} -> io:format("No msg. found!~n"),
		no_msg
	end.



