package com.vmware.tanzu.managedsvc.demo.service.impl;

import com.vmware.tanzu.managedsvc.demo.entity.TransactionEntity;
import com.vmware.tanzu.managedsvc.demo.model.Transaction;
import com.vmware.tanzu.managedsvc.demo.service.TransactionProcessor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service("DEBIT_CARD")
public class DebitCardTransaction implements TransactionProcessor {
    @Override
    public void validateTransaction(Transaction transaction) {

    }

    @Override
    public List<TransactionEntity> getFraudTransactions() {
        return null;
    }
}
