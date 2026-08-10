package com.ttc.api.dto;

import java.util.Map;

public record TemplateCreateReq(String name, Integer baseScore, Map<String, Double> weights) {
}