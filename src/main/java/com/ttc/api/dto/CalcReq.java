package com.ttc.api.dto;

import java.util.Map;

public record CalcReq(Long employeeId, Long templateId, Map<String, Integer> scoreMap) {
}