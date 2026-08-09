package com.ttc.management.repository;

import com.ttc.management.entity.KpiTemplateEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface KpiTemplateRepository extends JpaRepository<KpiTemplateEntity, Long> {
}