# ADR 0001: Transactional outbox instead of writing to the DB and Kafka separately

Status: accepted

Context: The order service must save an order and publish an event. Two separate writes can leave them inconsistent if the service crashes between them.

Decision: Write the order and an outbox row in one database transaction. A relay publishes outbox rows to Kafka.

Consequences: No lost events. Events can be published more than once, so consumers dedupe. Adds a relay component and a polling delay.
