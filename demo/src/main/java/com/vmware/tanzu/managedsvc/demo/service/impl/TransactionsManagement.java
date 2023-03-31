package com.vmware.tanzu.managedsvc.demo.service.impl;

import com.vmware.tanzu.managedsvc.demo.entity.TransactionEntity;
import com.vmware.tanzu.managedsvc.demo.repositories.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class TransactionsManagement {
    private final TransactionRepository transactionRepository;

    public List<TransactionEntity> getFraudTransactions() {
        return (List<TransactionEntity>) transactionRepository.findAll();
    }

    public void deleteTransactions() {
        transactionRepository.deleteAll();
    }
}
