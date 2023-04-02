package com.vmware.tanzu.managedsvc.demo.controllers;

import com.vmware.tanzu.managedsvc.demo.model.RmqTransaction;
import com.vmware.tanzu.managedsvc.demo.publishers.TransactionPublisher;
import com.vmware.tanzu.managedsvc.demo.service.impl.GemfireTransactions;
import com.vmware.tanzu.managedsvc.demo.service.impl.TransactionsManagement;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/demo")
@RequiredArgsConstructor
@Slf4j
public class MessageController {
    private final TransactionPublisher transactionPublisher;
    private final TransactionsManagement transactionsManagement;
    private final GemfireTransactions gemfireTransactions;

    @PostMapping
    public @ResponseBody ResponseEntity<?> send(@RequestBody RmqTransaction transaction) {
        transactionPublisher.send(transaction);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public @ResponseBody ResponseEntity<?> getTransactions() {
        log.info("Getting transactions");
        return ResponseEntity.ok(transactionsManagement.getFraudTransactions());
    }

    @DeleteMapping
    public @ResponseBody ResponseEntity<?> deleteAllTransactions() {
        log.info("Deleting transactions");
        transactionsManagement.deleteTransactions();
        gemfireTransactions.deleteAllTransactions();
        return ResponseEntity.ok().build();
    }
}
