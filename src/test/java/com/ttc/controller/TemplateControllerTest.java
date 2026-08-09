package com.ttc.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ttc.api.dto.TemplateCreateReq;
import com.ttc.common.Result;
import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.service.TemplateService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TemplateController.class)
class TemplateControllerTest {

    @Autowired
    private MockMvc mockMvc;

    //@MockitoBean
    @MockBean
    private TemplateService templateService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void testCreateTemplate() throws Exception {
        Map<String, Double> weights = Map.of("sales", 0.5, "service", 0.5);
        TemplateCreateReq req = new TemplateCreateReq("SalesKPI", 100, weights);

        KpiTemplateEntity saved = new KpiTemplateEntity();
        saved.setId(2L);
        saved.setName("SalesKPI");

        when(templateService.createTemplate(any(TemplateCreateReq.class))).thenReturn(saved);

        mockMvc.perform(post("/api/management/template")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.id").value(2));
    }
}