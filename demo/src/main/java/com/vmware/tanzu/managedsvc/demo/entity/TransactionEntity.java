package com.vmware.tanzu.managedsvc.demo.entity;

import com.vmware.tanzu.managedsvc.demo.enums.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder(toBuilder = true)
@Table(name = "Transaction")
public class TransactionEntity {
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Id
    @Column
    private int id;

    @Column
    private String dateTime;

    @Column
    private TransactionType transactionType;

    @Column
    private String cardNumber;

    @Column
    private String amount;

    @Column
    private String location;

    @Column
    private double lat;

    @Column
    private double lon;

    @Column
    private Boolean isFraud;

    @Column
    private String rmqMsgArriveTime;

    @Column
    private String msgProcessStartTime;

    @Column
    private String msgProcessCompletionTime;
}
