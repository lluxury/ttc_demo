package com.ttc.management.service;

import com.ttc.api.dto.TemplateCreateReq;
import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.repository.KpiTemplateRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TemplateServiceTest {

    @Mock
    private KpiTemplateRepository repository;

    @InjectMocks
    private TemplateService templateService;

    @Test
    void testCreateTemplate() {
        // 准备请求
        Map<String, Double> weights = Map.of("a", 0.5, "b", 0.5);
        TemplateCreateReq req = new TemplateCreateReq("TestKPI", 100, weights);

        // 模拟保存行为
        KpiTemplateEntity savedEntity = new KpiTemplateEntity();
        savedEntity.setId(100L);
        savedEntity.setName("TestKPI");
        when(repository.save(any(KpiTemplateEntity.class))).thenReturn(savedEntity);

        // 执行
        KpiTemplateEntity result = templateService.createTemplate(req);

        // 验证
        assertNotNull(result);
        assertEquals(100L, result.getId());
        assertEquals("TestKPI", result.getName());
        verify(repository, times(1)).save(any());
    }

    @Test
    void testGetTemplate_Found() {
        KpiTemplateEntity entity = new KpiTemplateEntity();
        entity.setId(1L);
        entity.setName("Existing");
        when(repository.findById(1L)).thenReturn(Optional.of(entity));

        KpiTemplateEntity result = templateService.getTemplate(1L);
        assertNotNull(result);
        assertEquals("Existing", result.getName());
    }

    @Test
    void testGetTemplate_NotFound() {
        when(repository.findById(999L)).thenReturn(Optional.empty());
        KpiTemplateEntity result = templateService.getTemplate(999L);
        assertNull(result);
    }
}