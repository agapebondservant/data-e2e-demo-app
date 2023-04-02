package com.vmware.tanzu.managedsvc.demo.model;

import com.vmware.tanzu.managedsvc.demo.enums.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Data
@AllArgsConstructor
@NoArgsConstructor
public class RmqTransaction {
    private String dateTime;

    private TransactionType transactionType;

    private String cardNumber;

    private String amount;

    private String location;

    private double lat;

    private double lon;
}
