Test program for RabbitMQ Erlang client.

The current module (create_customer_listener) is a bit misleadingly named. 
It can 
* create a connection to a localhost rabbit mq with the default guest user
* create a queue
* send messages to the queue
* poll for messages from a queue
