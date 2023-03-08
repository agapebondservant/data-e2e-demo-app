package com.vmware.tanzu.managedsvc.demo.publishers;

import com.vmware.tanzu.managedsvc.demo.model.Transaction;
import lombok.RequiredArgsConstructor;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class TransactionPublisher {
    private final RabbitTemplate rabbitTemplate;

    @Value("${rmq.listeners.queue.fraud-transactions}")
    private String queue;

    public void send(Transaction transaction) {
        rabbitTemplate.convertAndSend(this.queue, transaction);
    }
}
