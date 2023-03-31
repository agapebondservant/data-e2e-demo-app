package com.vmware.tanzu.managedsvc.demo.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vmware.tanzu.managedsvc.demo.model.Transaction;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

@Component
@Slf4j
public class GemfireTransactions {

    @Value("${gemfire.url}")
    public String gemfireUrl;

    @Value("${gemfire.region}")
    public String gemfireRegion;

    public List<Transaction> getTransactions(String key) {
        List<Transaction> list = new ArrayList<>();
        try {
            String url = gemfireUrl + "?cmd=get --key=" + key + " --region=" + gemfireRegion;
            log.info("Fetching data from {}", url);

            RestTemplate restTemplate = new RestTemplate();
            String response = restTemplate.getForObject(url, String.class);
            ObjectMapper mapper = new ObjectMapper();

            JsonNode jsonNode = mapper.readTree(response);
            JsonNode mdsRegionNode = jsonNode.get("content");
            if (mdsRegionNode.isObject()) {
                JsonNode value = mdsRegionNode.get("data-info").get("content").get("Value");
                if (!value.asText().equals("null")) {
                    String data = URLDecoder.decode(value.asText(), StandardCharsets.UTF_8.toString());
                    data = data.substring(1, data.length() - 1);
                    Transaction[] transactions = mapper.readValue(data, Transaction[].class);
                    if (transactions != null) {
                        list = new LinkedList<>(Arrays.asList(transactions));
                    }
                }
            }

            return list;
        } catch (Exception e) {
            log.error(e.getMessage());
            e.printStackTrace();
        }

        return list;
    }

    public void addTransaction(Transaction transaction, List<Transaction> existingTransactions) {
        if (existingTransactions == null) {
            existingTransactions = new ArrayList<>();
        }
        existingTransactions.add(transaction);

        try {
            String data = toJsonArray(existingTransactions);
            data = URLEncoder.encode(data, StandardCharsets.UTF_8.toString());

            String url = gemfireUrl + "?cmd= " + "put --key=" + transaction.getCardNumber() + " --value=" + data + " --region=" + gemfireRegion;
            log.info("Adding data to {}", url);

            RestTemplate restTemplate = new RestTemplate();
            restTemplate.getForObject(url, String.class);
        } catch (Exception e) {
            log.error(e.getMessage());
            e.printStackTrace();
        }
    }

    public void deleteAllTransactions() {
        try {
            String url = gemfireUrl + "?cmd= " + "remove --region=" + gemfireRegion + " --all=true";
            log.info("Deleting data from {}", url);

            RestTemplate restTemplate = new RestTemplate();
            restTemplate.getForObject(url, String.class);
        } catch (Exception e) {
            log.error(e.getMessage());
            e.printStackTrace();
        }
    }

    @SneakyThrows
    private String toJsonArray(List<Transaction> list) {
        ObjectMapper mapper = new ObjectMapper();
        return mapper.writeValueAsString(list);
    }
}
