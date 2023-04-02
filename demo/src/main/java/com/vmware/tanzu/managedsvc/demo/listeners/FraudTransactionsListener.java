package com.vmware.tanzu.managedsvc.demo.listeners;

import com.vmware.tanzu.managedsvc.demo.model.RmqTransaction;
import com.vmware.tanzu.managedsvc.demo.service.TransactionProcessor;
import com.vmware.tanzu.managedsvc.demo.service.impl.CreditCardTransaction;
import com.vmware.tanzu.managedsvc.demo.service.impl.DebitCardTransaction;
import com.vmware.tanzu.managedsvc.demo.utils.Utility;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.handler.annotation.Payload;

@Configuration
@Slf4j
@AllArgsConstructor
public class FraudTransactionsListener {

    private final CreditCardTransaction creditCardTransaction;
    private final DebitCardTransaction debitCardTransaction;

    @RabbitListener(queues = "${rmq.listeners.queue.fraud-transactions}")
    public void transactionListener(@Payload RmqTransaction transaction) {
        String rmqMsgArrivalTime = Utility.getCurrentDateTime();
        transaction.setDateTime(rmqMsgArrivalTime);

        TransactionProcessor transactionProcessor = getTransactionProcessor(transaction);
        if (transactionProcessor != null) {
            transactionProcessor.validateTransaction(transaction);
        }
    }

    private TransactionProcessor getTransactionProcessor(RmqTransaction transaction) {
        if (transaction.getTransactionType() != null) {
            switch (transaction.getTransactionType()) {
                case CREDIT_CARD:
                    return creditCardTransaction;
                case DEBIT_CARD:
                    return debitCardTransaction;
                default:
                    throw new IllegalArgumentException("Unknown transaction type: " + transaction.getTransactionType());
            }
        }
        throw new IllegalArgumentException("Missing Transaction type");
    }
}
