package com.vmware.tanzu.managedsvc.demo.controllers;

import com.vmware.tanzu.managedsvc.demo.model.Transaction;
import com.vmware.tanzu.managedsvc.demo.publishers.TransactionPublisher;
import com.vmware.tanzu.managedsvc.demo.service.TransactionProcessor;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.BeanFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/demo")
@RequiredArgsConstructor
public class MessageController {
    private final TransactionPublisher transactionPublisher;
    private final BeanFactory beanFactory;

    @CrossOrigin(origins = "http://localhost:55625")
    @PostMapping
    public @ResponseBody ResponseEntity<?> send(@RequestBody Transaction transaction) {
        transactionPublisher.send(transaction);
        return ResponseEntity.ok().build();
    }

    @CrossOrigin(origins = "http://localhost:55625")
    @GetMapping
    public @ResponseBody ResponseEntity<?> getTransactions() {
        TransactionProcessor transactionProcessor = beanFactory.getBean("CREDIT_CARD", TransactionProcessor.class);
        return ResponseEntity.ok(transactionProcessor.getFraudTransactions());
    }
}
