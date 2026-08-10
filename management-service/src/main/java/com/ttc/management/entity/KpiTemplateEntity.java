package com.ttc.management.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "t_kpi_template")
@Data
public class KpiTemplateEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private Integer baseScore; // 基础分，如100
    @Lob
    @Column(columnDefinition = "TEXT")
    private String weights; // JSON字符串，如 {"代码质量":0.4,"响应速度":0.3,"团队协作":0.3}
    // ... 省略 getter/setter（或用Lombok @Data）
}