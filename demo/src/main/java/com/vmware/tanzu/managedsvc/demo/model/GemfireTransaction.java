package com.vmware.tanzu.managedsvc.demo.model;

import com.vmware.tanzu.managedsvc.demo.enums.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class GemfireTransaction {
    private String dateTime;

    private TransactionType transactionType;

    private String cardNumber;

    private String location;
}
