package com.ttc.initializer;

import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.repository.KpiTemplateRepository;
import com.ttc.management.service.TemplateService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DataInitializerTest {

    @Mock
    private KpiTemplateRepository repository;

    @Mock
    private TemplateService templateService;

    @InjectMocks
    private DataInitializer dataInitializer;

    @Test
    void testRun_WhenDatabaseEmpty_InitializesTemplate() {
        when(repository.count()).thenReturn(0L);
        // 模拟保存后返回实体
        KpiTemplateEntity saved = new KpiTemplateEntity();
        saved.setId(1L);
        when(repository.save(any(KpiTemplateEntity.class))).thenReturn(saved);

        dataInitializer.run(null);

        verify(repository, times(1)).save(any(KpiTemplateEntity.class));
        verify(templateService, times(1)).getTemplate(1L); // 确保预热缓存
    }

    @Test
    void testRun_WhenDatabaseNotEmpty_SkipsInit() {
        when(repository.count()).thenReturn(5L);

        dataInitializer.run(null);

        verify(repository, never()).save(any(KpiTemplateEntity.class));
        verify(templateService, never()).getTemplate(anyLong());
    }
}