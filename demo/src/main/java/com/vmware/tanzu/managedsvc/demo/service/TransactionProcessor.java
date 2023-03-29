package com.vmware.tanzu.managedsvc.demo.service;

import com.vmware.tanzu.managedsvc.demo.model.Transaction;

public interface TransactionProcessor {
    void validateTransaction(Transaction transaction);
}
