package com.vmware.tanzu.managedsvc.demo.service;

import com.vmware.tanzu.managedsvc.demo.model.RmqTransaction;

public interface TransactionProcessor {
    void validateTransaction(RmqTransaction transaction);
}
