package com.vmware.tanzu.managedsvc.demo.service;

import com.vmware.tanzu.managedsvc.demo.entity.TransactionEntity;
import com.vmware.tanzu.managedsvc.demo.model.Transaction;

import java.util.List;

public interface TransactionProcessor {
    void validateTransaction(Transaction transaction);
    List<TransactionEntity> getFraudTransactions();
}
