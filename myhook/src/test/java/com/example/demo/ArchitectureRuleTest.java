package com.example.demo;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.lang.ArchRule;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.core.importer.ImportOption.Predefined.DO_NOT_INCLUDE_JARS;
import static com.tngtech.archunit.core.importer.ImportOption.Predefined.DO_NOT_INCLUDE_TESTS;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.layeredArchitecture;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

public class ArchitectureRuleTest {

    /**
     * 请替换为你的项目根包名，例如 com.company.order。
     */
    private static final String ROOT_PACKAGE = "com.example.demo";

    private static final JavaClasses BUSINESS_CLASSES = new ClassFileImporter()
            .withImportOption(DO_NOT_INCLUDE_TESTS)
            .withImportOption(DO_NOT_INCLUDE_JARS)
            .importPackages(ROOT_PACKAGE);

    private static final ArchRule LAYERED_ARCHITECTURE_RULE = layeredArchitecture()
            .consideringAllDependencies()
            .layer("Controller").definedBy("..controller..")
            .layer("Service").definedBy("..service..")
            .layer("DAO").definedBy("..dao..", "..mapper..")
            .layer("Entity").definedBy("..entity..")
            .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
            .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
            .whereLayer("DAO").mayOnlyBeAccessedByLayers("Service")
            .whereLayer("Entity").mayOnlyBeAccessedByLayers("DAO", "Service");

    private static final ArchRule NO_ENTITY_IN_CONTROLLER_RULE = noClasses()
            .that().resideInAPackage("..controller..")
            .should().dependOnClassesThat().resideInAPackage("..entity..");

    private static final ArchRule CONTROLLER_MUST_NOT_ACCESS_DAO_RULE = noClasses()
            .that().resideInAPackage("..controller..")
            .should().dependOnClassesThat().resideInAnyPackage("..dao..", "..mapper..");

    private static final ArchRule SERVICE_MUST_NOT_ACCESS_CONTROLLER_RULE = noClasses()
            .that().resideInAPackage("..service..")
            .should().dependOnClassesThat().resideInAPackage("..controller..");

    private static final ArchRule TRANSACTIONAL_MUST_BE_PUBLIC_RULE = methods()
            .that().areAnnotatedWith("org.springframework.transaction.annotation.Transactional")
            .should().bePublic();

    @Test
    void testLayeredArchitecture() {
        LAYERED_ARCHITECTURE_RULE.check(BUSINESS_CLASSES);
    }

    @Test
    void testNoEntityInController() {
        NO_ENTITY_IN_CONTROLLER_RULE.check(BUSINESS_CLASSES);
    }

    @Test
    void testControllerMustNotAccessDao() {
        CONTROLLER_MUST_NOT_ACCESS_DAO_RULE.check(BUSINESS_CLASSES);
    }

    @Test
    void testServiceMustNotAccessController() {
        SERVICE_MUST_NOT_ACCESS_CONTROLLER_RULE.check(BUSINESS_CLASSES);
    }

    @Test
    void testTransactionalMustBePublic() {
        TRANSACTIONAL_MUST_BE_PUBLIC_RULE.check(BUSINESS_CLASSES);
    }
}
