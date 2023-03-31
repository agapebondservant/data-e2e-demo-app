package com.vmware.tanzu.managedsvc.demo.service.impl;

import com.vmware.tanzu.managedsvc.demo.entity.TransactionEntity;
import com.vmware.tanzu.managedsvc.demo.model.Transaction;
import com.vmware.tanzu.managedsvc.demo.repositories.TransactionRepository;
import com.vmware.tanzu.managedsvc.demo.service.TransactionProcessor;
import com.vmware.tanzu.managedsvc.demo.utils.Utility;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service("CREDIT_CARD")
@Slf4j
@RequiredArgsConstructor
public class CreditCardTransaction implements TransactionProcessor {
    @Value("${fraud.detection.distance-threshold-in-kms}")
    public Integer kms;

    @Value("${fraud.detection.time-threshold-in-seconds}")
    public Integer seconds;

    private final TransactionRepository transactionRepository;
    private final GemfireTransactions gemfireTransactions;
    private final String pattern = "yyyy-MM-dd'T'HH:mm:ss";

    @Override
    public void validateTransaction(Transaction transaction) {
        log.info("Validating transaction {}", transaction);
        List<TransactionEntity> transactions = new ArrayList<>();
        List<Transaction> existingTransactions = gemfireTransactions.getTransactions(transaction.getCardNumber());
        if (existingTransactions != null) {
            log.info("Found {} transactions in gemfire", existingTransactions.size());
            for (Transaction t : existingTransactions) {
                transactions.add(Utility.toDto(t));
            }
        } else {
            log.info("Nothing found in gemfire");
            transactions = transactionRepository.findByCardNumber(transaction.getCardNumber());
        }

        boolean isFraudTransaction = isFraudulent(transactions, transaction);

        TransactionEntity responseDto = Utility.toDto(transaction);
        if (isFraudTransaction) {
            responseDto.setIsFraud(true);
            log.error("Fraud transaction found !!!");
        } else {
            responseDto.setIsFraud(false);
            log.info("Valid transaction");
        }

        gemfireTransactions.addTransaction(transaction, existingTransactions);
        transactionRepository.save(responseDto);
    }

    // checks if the new transaction is fraudulent based on location
    private boolean isFraudulent(List<TransactionEntity> transactionList, Transaction newTransaction) {
        // check all previous transactions for location within given kms of the new transaction
        for (TransactionEntity transaction : transactionList) {
            if (!transaction.getCardNumber().equals(newTransaction.getCardNumber())) { // if different cards, don't compare
                continue;
            }
            if (transaction.getLocation().equals(newTransaction.getLocation())) { // if same location, don't compare
                continue;
            }
            if (!transaction.getTransactionType().equals(newTransaction.getTransactionType())) {
                continue;
            }
            if (Utility.distance(transaction.getLat(), transaction.getLon(), newTransaction.getLat(), newTransaction.getLon()) > kms
                    && Utility.differenceInSeconds(transaction.getDateTime(), newTransaction.getDateTime(), pattern) < seconds) {
                // location within given kms, possible fraud
                return true;
            }
        }
        // no fraudulent transactions found
        return false;
    }

}
