package com.vmware.tanzu.managedsvc.demo.repositories;

import com.vmware.tanzu.managedsvc.demo.entity.TransactionEntity;
import org.springframework.data.repository.CrudRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransactionRepository extends CrudRepository<TransactionEntity, Integer> {
    List<TransactionEntity> findByCardNumber(String cardNumber);
}
