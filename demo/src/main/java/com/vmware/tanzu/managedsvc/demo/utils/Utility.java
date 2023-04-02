package com.vmware.tanzu.managedsvc.demo.utils;

import com.vmware.tanzu.managedsvc.demo.constants.AppConstants;
import com.vmware.tanzu.managedsvc.demo.entity.TransactionEntity;
import com.vmware.tanzu.managedsvc.demo.model.GemfireTransaction;
import com.vmware.tanzu.managedsvc.demo.model.RmqTransaction;
import com.vmware.tanzu.managedsvc.demo.model.Transaction;

import java.text.SimpleDateFormat;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.TimeZone;

public class Utility {
    // helper method to calculate distance between two locations
    public static double distance(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371; // earth radius in km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double lat1r = Math.toRadians(lat1);
        double lat2r = Math.toRadians(lat2);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1r) * Math.cos(lat2r);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }

    public static long differenceInSeconds(String dateTimeString1, String dateTimeString2, String pattern) {
        // Parse the date-time strings using the specified pattern
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern(pattern);
        LocalDateTime dateTime1 = LocalDateTime.parse(dateTimeString1, formatter);
        LocalDateTime dateTime2 = LocalDateTime.parse(dateTimeString2, formatter);

        // Calculate the duration between the two date-times
        Duration duration = Duration.between(dateTime1, dateTime2);

        // Return the duration in seconds
        return Math.abs(duration.getSeconds());
    }

    public static TransactionEntity toDtoFromGemfire(GemfireTransaction transaction) {
        return TransactionEntity.builder()
                .cardNumber(transaction.getCardNumber())
                .transactionType(transaction.getTransactionType())
                .dateTime(transaction.getDateTime())
                .location(transaction.getLocation())
                .build();
    }

    public static TransactionEntity toDtoFromRmq(RmqTransaction transaction) {
        return TransactionEntity.builder()
                .cardNumber(transaction.getCardNumber())
                .location(transaction.getLocation())
                .dateTime(transaction.getDateTime())
                .lat(transaction.getLat())
                .lon(transaction.getLon())
                .amount(transaction.getAmount())
                .transactionType(transaction.getTransactionType())
                .build();
    }

    public static GemfireTransaction toGemfireDtoFromRmq(RmqTransaction transaction) {
        return GemfireTransaction.builder()
                .cardNumber(transaction.getCardNumber())
                .location(transaction.getLocation())
                .dateTime(transaction.getDateTime())
                .transactionType(transaction.getTransactionType())
                .build();
    }

    public static String getCurrentDateTime() {
        Date now = new Date();
        SimpleDateFormat dateFormat = new SimpleDateFormat(AppConstants.pattern);
        dateFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
        return dateFormat.format(now);
    }
}
