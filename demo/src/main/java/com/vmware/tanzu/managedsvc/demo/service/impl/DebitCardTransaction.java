package com.vmware.tanzu.managedsvc.demo.service.impl;

import com.vmware.tanzu.managedsvc.demo.constants.AppConstants;
import com.vmware.tanzu.managedsvc.demo.entity.TransactionEntity;
import com.vmware.tanzu.managedsvc.demo.model.GemfireTransaction;
import com.vmware.tanzu.managedsvc.demo.model.RmqTransaction;
import com.vmware.tanzu.managedsvc.demo.repositories.TransactionRepository;
import com.vmware.tanzu.managedsvc.demo.service.TransactionProcessor;
import com.vmware.tanzu.managedsvc.demo.utils.Utility;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service("DEBIT_CARD")
@Slf4j
@RequiredArgsConstructor
public class DebitCardTransaction implements TransactionProcessor {
    @Value("${fraud.detection.distance-threshold-in-kms}")
    public Integer kms;

    @Value("${fraud.detection.time-threshold-in-seconds}")
    public Integer seconds;

    private final TransactionRepository transactionRepository;
    private final GemfireTransactions gemfireTransactions;

    @Override
    public void validateTransaction(RmqTransaction transaction) {
        log.info("Validating transaction {}", transaction);
        String msgProcessStartTime = Utility.getCurrentDateTime();
        List<TransactionEntity> transactions = new ArrayList<>();
        List<GemfireTransaction> existingTransactions = gemfireTransactions.getTransactions(transaction.getCardNumber());
        if (existingTransactions != null) {
            log.info("Found {} transactions in gemfire", existingTransactions.size());
            for (GemfireTransaction t : existingTransactions) {
                transactions.add(Utility.toDtoFromGemfire(t));
            }
        } else {
            log.info("Nothing found in gemfire");
            transactions = transactionRepository.findByCardNumber(transaction.getCardNumber());
        }

        boolean isFraudTransaction = isFraudulent(transactions, transaction);

        TransactionEntity responseDto = Utility.toDtoFromRmq(transaction);
        if (isFraudTransaction) {
            responseDto.setIsFraud(true);
            log.error("Fraud transaction found !!!");
        } else {
            responseDto.setIsFraud(false);
            log.info("Valid transaction");
        }

        responseDto.setRmqMsgArriveTime(transaction.getDateTime());
        responseDto.setMsgProcessStartTime(msgProcessStartTime);
        responseDto.setMsgProcessCompletionTime(Utility.getCurrentDateTime());
        gemfireTransactions.addTransaction(Utility.toGemfireDtoFromRmq(transaction), existingTransactions);
        transactionRepository.save(responseDto);
    }

    // checks if the new transaction is fraudulent based on location
    private boolean isFraudulent(List<TransactionEntity> transactionList, RmqTransaction newTransaction) {
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
                    && Utility.differenceInSeconds(transaction.getDateTime(), newTransaction.getDateTime(), AppConstants.pattern) < seconds) {
                // location within given kms, possible fraud
                return true;
            }
        }
        // no fraudulent transactions found
        return false;
    }
}
