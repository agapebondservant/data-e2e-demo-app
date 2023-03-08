package com.vmware.tanzu.managedsvc.demo.service.impl;

import com.vmware.tanzu.managedsvc.demo.entity.TransactionEntity;
import com.vmware.tanzu.managedsvc.demo.model.Transaction;
import com.vmware.tanzu.managedsvc.demo.repositories.TransactionRepository;
import com.vmware.tanzu.managedsvc.demo.service.TransactionProcessor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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
                transactions.add(toDto(t));
            }
        } else {
            log.info("Nothing found in gemfire");
            transactions = transactionRepository.findByCardNumber(transaction.getCardNumber());
        }

        boolean isFraudTransaction = isFraudulent(transactions, transaction);

        TransactionEntity responseDto = toDto(transaction);
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

    @Override
    public List<TransactionEntity> getFraudTransactions() {
        return (List<TransactionEntity>) transactionRepository.findAll();
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
            if (distance(transaction.getLat(), transaction.getLon(), newTransaction.getLat(), newTransaction.getLon()) > kms
                    && differenceInSeconds(transaction.getDateTime(), newTransaction.getDateTime(), pattern) < seconds) {
                // location within given kms, possible fraud
                return true;
            }
        }
        // no fraudulent transactions found
        return false;
    }

    // helper method to calculate distance between two locations
    private double distance(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371; // earth radius in km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double lat1r = Math.toRadians(lat1);
        double lat2r = Math.toRadians(lat2);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1r) * Math.cos(lat2r);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        log.info("Distance: {}", R * c);
        return R * c;
    }

    private long differenceInSeconds(String dateTimeString1, String dateTimeString2, String pattern) {
        // Parse the date-time strings using the specified pattern
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern);
        LocalDateTime dateTime1 = LocalDateTime.parse(dateTimeString1, formatter);
        LocalDateTime dateTime2 = LocalDateTime.parse(dateTimeString2, formatter);

        // Calculate the duration between the two date-times
        Duration duration = Duration.between(dateTime1, dateTime2);

        // Return the duration in seconds
        log.info("Time difference: {}", duration.getSeconds());
        return Math.abs(duration.getSeconds());
    }

    private TransactionEntity toDto(Transaction transaction) {
        return TransactionEntity.builder().amount(transaction.getAmount())
                .cardNumber(transaction.getCardNumber())
                .transactionType(transaction.getTransactionType())
                .dateTime(transaction.getDateTime())
                .lat(transaction.getLat())
                .lon(transaction.getLon())
                .location(transaction.getLocation())
                .build();
    }
}
