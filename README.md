# Web API Profissional - Clientes, Produtos e Pedidos de Venda

> Material didático e escopo executável para construir uma API REST com Java 21, Spring Boot, PostgreSQL e Docker.  
> Princípio central: **entidades JPA nunca são expostas pela API**. Toda entrada e saída utiliza DTOs, preferencialmente `record`.

## 1. Objetivo do projeto

Construir uma API para:

- cadastrar, consultar, atualizar e desativar clientes;
- cadastrar, consultar, atualizar e desativar produtos;
- criar pedidos de venda com vários itens;
- consultar pedidos e seus itens;
- cancelar pedidos;
- calcular subtotal e total no servidor;
- impedir operações inválidas, como vender produto inativo ou alterar pedido cancelado.

O projeto é didático, mas adota decisões adequadas a uma aplicação real. Autenticação, autorização, estoque, pagamento, emissão fiscal e integração externa ficam fora do primeiro escopo e podem ser evoluções posteriores.

## 2. Tecnologias e versões

- Java 21
- Spring Boot 3.5.x (utilize a última versão de manutenção disponível da linha escolhida)
- Maven
- Spring Web
- Spring Data JPA
- Spring Validation
- PostgreSQL
- Flyway
- MapStruct
- Springdoc OpenAPI
- SLF4J/Logback
- JUnit 5, Mockito e Testcontainers

Ajuste as versões das dependências pelo Spring Initializr e pela documentação oficial no momento de iniciar o projeto. Não misture versões incompatíveis do Spring Framework, Hibernate e Jakarta APIs.

### Dependências Maven

No Spring Initializr, selecione Spring Web, Spring Data JPA, Validation, PostgreSQL Driver e Flyway Migration. Acrescente MapStruct, Lombok **não** deve ser adicionado, Springdoc e dependências de teste.

Exemplo de dependências centrais (as versões devem ser alinhadas ao BOM do projeto):

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-flyway</artifactId>
    </dependency>
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-database-postgresql</artifactId>
    </dependency>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct</artifactId>
        <version>${mapstruct.version}</version>
    </dependency>
    <dependency>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct-processor</artifactId>
        <version>${mapstruct.version}</version>
        <scope>provided</scope>
    </dependency>
    <dependency>
        <groupId>org.springdoc</groupId>
        <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
        <version>${springdoc.version}</version>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>postgresql</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

Configure o `maven-compiler-plugin` com Java 21 e o processador do MapStruct. O processamento de anotações é necessário para gerar as implementações dos mappers. Não use `componentModel = "spring"` sem configurar o annotation processor.

## 3. Organização dos pacotes

Organize por funcionalidade (feature package), mantendo as responsabilidades separadas:

```text
src/main/java/com/exemplo/vendas/
├── VendasApplication.java
├── cliente/
│   ├── controller/ClienteController.java
│   ├── dto/ClienteCreateRequest.java
│   ├── dto/ClienteUpdateRequest.java
│   ├── dto/ClienteResponse.java
│   ├── entity/Cliente.java
│   ├── mapper/ClienteMapper.java
│   ├── repository/ClienteRepository.java
│   ├── service/ClienteService.java
│   ├── service/ClienteServiceImpl.java
│   └── validator/ClienteValidator.java
├── produto/
│   ├── controller/ProdutoController.java
│   ├── dto/ProdutoCreateRequest.java
│   ├── dto/ProdutoUpdateRequest.java
│   ├── dto/ProdutoResponse.java
│   ├── entity/Produto.java
│   ├── mapper/ProdutoMapper.java
│   ├── repository/ProdutoRepository.java
│   ├── service/ProdutoService.java
│   ├── service/ProdutoServiceImpl.java
│   └── validator/ProdutoValidator.java
├── pedido/
│   ├── controller/PedidoController.java
│   ├── dto/PedidoCreateRequest.java
│   ├── dto/PedidoItemRequest.java
│   ├── dto/PedidoResponse.java
│   ├── dto/PedidoItemResponse.java
│   ├── entity/Pedido.java
│   ├── entity/PedidoItem.java
│   ├── entity/StatusPedido.java
│   ├── mapper/PedidoMapper.java
│   ├── repository/PedidoRepository.java
│   ├── service/PedidoService.java
│   ├── service/PedidoServiceImpl.java
│   └── validator/PedidoValidator.java
└── shared/
    ├── exception/ResourceNotFoundException.java
    ├── exception/BusinessException.java
    ├── exception/ConflictException.java
    ├── exception/GlobalExceptionHandler.java
    ├── exception/ApiErrorResponse.java
    ├── logging/CorrelationIdFilter.java
    └── config/MessageConfig.java

src/main/resources/
├── application.yml
├── messages.properties
├── messages_pt_BR.properties
├── messages_en.properties
└── db/migration/
    └── V1__create_initial_schema.sql
```

**Responsabilidade de cada camada**

| Camada | Responsabilidade | Não deve fazer |
|---|---|---|
| Controller | HTTP, status, parâmetros e DTOs | Regra de negócio ou SQL |
| DTO | Contrato de entrada/saída | Persistência |
| Service | Orquestração e regras de negócio | Conhecer detalhes HTTP |
| Validator | Regras específicas e reutilizáveis | Persistir dados |
| Repository | Consultas e persistência | Decidir regra comercial |
| Entity | Estado e mapeamento JPA | Ser devolvida ao cliente |
| Mapper | Converter Entity/DTO | Consultar banco ou decidir negócio |
| Exception Handler | Traduzir exceções para HTTP | Ocultar falhas inesperadas |
| MessageSource | Resolver mensagens por idioma | Conter regra de negócio |

## 4. Modelo de dados e regras

### 4.1 Cliente

Campos:

| Campo | Tipo | Regra |
|---|---|---|
| id | UUID | Gerado pelo servidor |
| nome | String | Obrigatório, 2 a 120 caracteres |
| email | String | Obrigatório, formato válido, único |
| documento | String | Obrigatório, único; armazenar normalizado |
| telefone | String | Opcional, até 20 caracteres |
| ativo | boolean | Padrão true |
| criadoEm | Instant | Gerado pelo servidor |
| atualizadoEm | Instant | Atualizado pelo servidor |

Regras:
- E-mail e documento não podem ser duplicados.
- Na edição, a verificação de duplicidade deve ignorar o próprio cliente.
- Desativar cliente não apaga seu histórico de pedidos.
- Não permitir novo pedido para cliente inativo.
- Não aceitar `id`, `ativo`, `criadoEm` ou `atualizadoEm` enviados pelo usuário em requests de criação/edição.

### 4.2 Produto

| Campo | Tipo | Regra |
|---|---|---|
| id | UUID | Gerado pelo servidor |
| nome | String | Obrigatório, 2 a 150 caracteres |
| descricao | String | Opcional, até 500 caracteres |
| sku | String | Obrigatório e único |
| preco | BigDecimal | Maior que zero, escala máxima 2 |
| ativo | boolean | Padrão true |
| criadoEm | Instant | Gerado pelo servidor |
| atualizadoEm | Instant | Atualizado pelo servidor |

Regras:
- SKU não pode se repetir.
- Preço deve ser positivo.
- Produto inativo não pode entrar em novo pedido.
- A edição do preço não altera pedidos já gravados: o item do pedido guarda o preço praticado no momento da venda.
- Não utilizar `double` ou `float` para valores monetários. Usar `BigDecimal`.

### 4.3 Pedido e item

Pedido:

| Campo | Tipo | Regra |
|---|---|---|
| id | UUID | Gerado pelo servidor |
| numero | String/long | Gerado pelo servidor |
| cliente | Cliente | Obrigatório |
| status | Enum | ABERTO, CANCELADO |
| total | BigDecimal | Calculado pelo servidor |
| criadoEm | Instant | Gerado pelo servidor |
| atualizadoEm | Instant | Atualizado pelo servidor |

Item:

| Campo | Tipo | Regra |
|---|---|---|
| id | UUID | Gerado pelo servidor |
| produto | Produto | Obrigatório |
| quantidade | Integer | Maior que zero |
| precoUnitario | BigDecimal | Copiado do preço vigente do produto |
| subtotal | BigDecimal | quantidade × preçoUnitario |

Regras:
- Pedido deve possuir pelo menos um item.
- Não pode haver produto repetido no mesmo pedido; o cliente deve enviar uma única linha por produto.
- O backend consulta o preço atual do produto. Nunca confia no preço enviado pelo cliente.
- Total = soma dos subtotais.
- Pedido cancelado não pode ser editado nem cancelado novamente.
- O cancelamento não exclui pedido nem itens.
- O primeiro escopo não implementa estoque. Não afirmar que há reserva ou baixa de estoque.

## 5. Contratos: DTOs com records

Exemplo de DTO de criação de cliente:

```java
package com.exemplo.vendas.cliente.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ClienteCreateRequest(
    @NotBlank(message = "{cliente.nome.obrigatorio}")
    @Size(min = 2, max = 120, message = "{cliente.nome.tamanho}")
    String nome,

    @NotBlank(message = "{cliente.email.obrigatorio}")
    @Email(message = "{cliente.email.invalido}")
    @Size(max = 160, message = "{cliente.email.tamanho}")
    String email,

    @NotBlank(message = "{cliente.documento.obrigatorio}")
    @Size(max = 20, message = "{cliente.documento.tamanho}")
    String documento,

    @Size(max = 20, message = "{cliente.telefone.tamanho}")
    String telefone
) {}
```

DTO de edição:

```java
public record ClienteUpdateRequest(
    @NotBlank(message = "{cliente.nome.obrigatorio}")
    @Size(min = 2, max = 120, message = "{cliente.nome.tamanho}")
    String nome,

    @NotBlank(message = "{cliente.email.obrigatorio}")
    @Email(message = "{cliente.email.invalido}")
    @Size(max = 160, message = "{cliente.email.tamanho}")
    String email,

    @NotBlank(message = "{cliente.documento.obrigatorio}")
    @Size(max = 20, message = "{cliente.documento.tamanho}")
    String documento,

    @Size(max = 20, message = "{cliente.telefone.tamanho}")
    String telefone
) {}
```

DTO de resposta:

```java
import java.time.Instant;
import java.util.UUID;

public record ClienteResponse(
    UUID id,
    String nome,
    String email,
    String documento,
    String telefone,
    boolean ativo,
    Instant criadoEm,
    Instant atualizadoEm
) {}
```

Não crie um único DTO para todos os cenários. Requests e responses têm propósitos diferentes. Por exemplo, `ativo` não aparece no request de edição porque a ativação/desativação possui operação própria.

DTO de produto:

```java
public record ProdutoCreateRequest(
    @NotBlank(message = "{produto.nome.obrigatorio}")
    @Size(min = 2, max = 150, message = "{produto.nome.tamanho}")
    String nome,

    @Size(max = 500, message = "{produto.descricao.tamanho}")
    String descricao,

    @NotBlank(message = "{produto.sku.obrigatorio}")
    @Size(max = 40, message = "{produto.sku.tamanho}")
    String sku,

    @NotNull(message = "{produto.preco.obrigatorio}")
    @DecimalMin(value = "0.00", inclusive = false,
                message = "{produto.preco.positivo}")
    @Digits(integer = 10, fraction = 2,
            message = "{produto.preco.digitos}")
    BigDecimal preco
) {}
```

Inclua os imports `jakarta.validation.constraints.*` e `java.math.BigDecimal`.

Request de pedido:

```java
public record PedidoCreateRequest(
    @NotNull(message = "{pedido.cliente.obrigatorio}")
    UUID clienteId,

    @NotEmpty(message = "{pedido.itens.obrigatorios}")
    @Size(max = 100, message = "{pedido.itens.limite}")
    List<@Valid PedidoItemRequest> itens
) {}

public record PedidoItemRequest(
    @NotNull(message = "{pedido.produto.obrigatorio}")
    UUID produtoId,

    @NotNull(message = "{pedido.quantidade.obrigatoria}")
    @Min(value = 1, message = "{pedido.quantidade.minima}")
    @Max(value = 10000, message = "{pedido.quantidade.maxima}")
    Integer quantidade
) {}
```

Response de pedido:

```java
public record PedidoItemResponse(
    UUID produtoId,
    String produtoNome,
    String sku,
    Integer quantidade,
    BigDecimal precoUnitario,
    BigDecimal subtotal
) {}

public record PedidoResponse(
    UUID id,
    Long numero,
    UUID clienteId,
    String clienteNome,
    String status,
    List<PedidoItemResponse> itens,
    BigDecimal total,
    Instant criadoEm,
    Instant atualizadoEm
) {}
```

## 6. Entidades JPA

Entidades são objetos internos de persistência. Não são contratos HTTP.

Exemplo simplificado:

```java
@Entity
@Table(name = "clientes")
public class Cliente {
    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, length = 120)
    private String nome;

    @Column(nullable = false, unique = true, length = 160)
    private String email;

    @Column(nullable = false, unique = true, length = 20)
    private String documento;

    @Column(length = 20)
    private String telefone;

    @Column(nullable = false)
    private boolean ativo = true;

    @Column(nullable = false, updatable = false)
    private Instant criadoEm;

    @Column(nullable = false)
    private Instant atualizadoEm;

    protected Cliente() {}

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        criadoEm = now;
        atualizadoEm = now;
    }

    @PreUpdate
    void preUpdate() {
        atualizadoEm = Instant.now();
    }

    // Construtor de domínio e getters explícitos.
    // Não disponibilize setters indiscriminadamente.
}
```

Para o projeto completo, implemente construtores e métodos de alteração explícitos, como `atualizarDados(...)` e `desativar()`. Isso evita que qualquer camada altere qualquer campo sem regra. Repita o padrão para Produto.

Para Pedido:
- `@ManyToOne(fetch = FetchType.LAZY)` para Cliente;
- `@OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true)` para itens;
- `@Enumerated(EnumType.STRING)` para status;
- `@Column(precision = 12, scale = 2)` para valores monetários;
- métodos de domínio para adicionar item e cancelar;
- não use `CascadeType.REMOVE` em Cliente ou Produto.

Não use `@Data` nem Lombok. Implemente getters e construtores explicitamente. Evite `toString()` incluindo relacionamentos LAZY para não disparar consultas nem gerar recursão.

## 7. Repository

Repositories devem conter consultas de persistência, não regras de negócio.

```java
public interface ClienteRepository extends JpaRepository<Cliente, UUID> {
    boolean existsByEmailIgnoreCase(String email);
    boolean existsByDocumento(String documento);
    boolean existsByEmailIgnoreCaseAndIdNot(String email, UUID id);
    boolean existsByDocumentoAndIdNot(String documento, UUID id);
}
```

```java
public interface ProdutoRepository extends JpaRepository<Produto, UUID> {
    boolean existsBySkuIgnoreCase(String sku);
    boolean existsBySkuIgnoreCaseAndIdNot(String sku, UUID id);
}
```

```java
public interface PedidoRepository extends JpaRepository<Pedido, UUID> {
    Optional<Pedido> findByNumero(Long numero);
}
```

Para listagens com paginação, utilize `Pageable` e retorne `Page<DTO>` ou converta a página no service. Não carregue listas ilimitadas em produção.

## 8. Validators com interface e reutilização

Separar validação de formato (Bean Validation) de validação de negócio.

- Bean Validation: campo obrigatório, tamanho, formato de e-mail, quantidade mínima.
- Validator de negócio: e-mail/documento/SKU únicos, cliente ativo, produto ativo, pedido em estado permitido.

A interface define o contrato:

```java
public interface Validator<T> {
    void validate(T input);
}
```

Para não confundir o validator de criação com o de edição, use tipos de entrada específicos:

```java
public interface ClienteCreateValidator {
    void validate(ClienteCreateRequest request);
}

public interface ClienteUpdateValidator {
    void validate(UUID id, ClienteUpdateRequest request);
}
```

Implementação:

```java
@Component
public class ClienteCreateValidatorImpl implements ClienteCreateValidator {
    private final ClienteRepository repository;

    public ClienteCreateValidatorImpl(ClienteRepository repository) {
        this.repository = repository;
    }

    @Override
    public void validate(ClienteCreateRequest request) {
        if (repository.existsByEmailIgnoreCase(request.email().trim())) {
            throw new ConflictException("cliente.email.duplicado");
        }
        if (repository.existsByDocumento(normalizarDocumento(request.documento()))) {
            throw new ConflictException("cliente.documento.duplicado");
        }
    }

    private String normalizarDocumento(String documento) {
        return documento.replaceAll("\\D", "");
    }
}
```

Na edição:

```java
@Component
public class ClienteUpdateValidatorImpl implements ClienteUpdateValidator {
    private final ClienteRepository repository;

    public ClienteUpdateValidatorImpl(ClienteRepository repository) {
        this.repository = repository;
    }

    @Override
    public void validate(UUID id, ClienteUpdateRequest request) {
        if (repository.existsByEmailIgnoreCaseAndIdNot(request.email().trim(), id)) {
            throw new ConflictException("cliente.email.duplicado");
        }
        if (repository.existsByDocumentoAndIdNot(
                normalizarDocumento(request.documento()), id)) {
            throw new ConflictException("cliente.documento.duplicado");
        }
    }

    private String normalizarDocumento(String documento) {
        return documento.replaceAll("\\D", "");
    }
}
```

**Atenção:** a validação prévia de unicidade melhora a mensagem ao usuário, mas não elimina condição de corrida. Duas requisições simultâneas podem passar no `exists...`. A constraint `UNIQUE` do PostgreSQL é a garantia final; trate a violação como conflito HTTP 409.

Crie também `ProdutoCreateValidator` e `ProdutoUpdateValidator` com o mesmo padrão para SKU. Para pedido, `PedidoValidator` valida cliente ativo, produtos ativos, duplicidade de produto no request e estado do pedido. O validator não deve calcular o total nem persistir o pedido.

## 9. MapStruct

O mapper só converte objetos. Não consulta repositório, não calcula preço e não executa validações.

```java
@Mapper(componentModel = "spring")
public interface ClienteMapper {
    ClienteResponse toResponse(Cliente entity);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "ativo", constant = "true")
    @Mapping(target = "criadoEm", ignore = true)
    @Mapping(target = "atualizadoEm", ignore = true)
    Cliente toEntity(ClienteCreateRequest request);

    void updateEntity(ClienteUpdateRequest request,
                      @MappingTarget Cliente entity);
}
```

Configure `unmappedTargetPolicy = ReportingPolicy.ERROR` para detectar campos não mapeados durante a compilação. Em update, ignore explicitamente campos controlados pelo servidor. Se o mapper não conseguir atualizar uma entidade por ausência de setters, prefira métodos de domínio explícitos e faça a atribuição no service ou use um método de mapper cuidadosamente restrito.

## 10. Service: regra de negócio e transação

Defina uma interface:

```java
public interface ClienteService {
    ClienteResponse criar(ClienteCreateRequest request);
    ClienteResponse buscarPorId(UUID id);
    Page<ClienteResponse> listar(Pageable pageable);
    ClienteResponse atualizar(UUID id, ClienteUpdateRequest request);
    void desativar(UUID id);
}
```

Implementação:

```java
@Service
public class ClienteServiceImpl implements ClienteService {
    private static final Logger log =
        LoggerFactory.getLogger(ClienteServiceImpl.class);

    private final ClienteRepository repository;
    private final ClienteMapper mapper;
    private final ClienteCreateValidator createValidator;
    private final ClienteUpdateValidator updateValidator;

    public ClienteServiceImpl(
            ClienteRepository repository,
            ClienteMapper mapper,
            ClienteCreateValidator createValidator,
            ClienteUpdateValidator updateValidator) {
        this.repository = repository;
        this.mapper = mapper;
        this.createValidator = createValidator;
        this.updateValidator = updateValidator;
    }

    @Override
    @Transactional
    public ClienteResponse criar(ClienteCreateRequest request) {
        createValidator.validate(request);
        Cliente entity = mapper.toEntity(request);
        entity.normalizarDados();
        Cliente salvo = repository.save(entity);
        log.info("Cliente cadastrado. clienteId={}", salvo.getId());
        return mapper.toResponse(salvo);
    }

    @Override
    @Transactional(readOnly = true)
    public ClienteResponse buscarPorId(UUID id) {
        return mapper.toResponse(obterOuFalhar(id));
    }

    @Override
    @Transactional(readOnly = true)
    public Page<ClienteResponse> listar(Pageable pageable) {
        return repository.findAll(pageable).map(mapper::toResponse);
    }

    @Override
    @Transactional
    public ClienteResponse atualizar(UUID id, ClienteUpdateRequest request) {
        Cliente entity = obterOuFalhar(id);
        updateValidator.validate(id, request);
        entity.atualizarDados(request.nome(), request.email(),
                              request.documento(), request.telefone());
        Cliente salvo = repository.save(entity);
        log.info("Cliente atualizado. clienteId={}", id);
        return mapper.toResponse(salvo);
    }

    @Override
    @Transactional
    public void desativar(UUID id) {
        Cliente entity = obterOuFalhar(id);
        entity.desativar();
        log.info("Cliente desativado. clienteId={}", id);
    }

    private Cliente obterOuFalhar(UUID id) {
        return repository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("cliente.nao.encontrado"));
    }
}
```

O código acima é um modelo de implementação: crie na entidade os métodos `normalizarDados`, `atualizarDados` e `desativar`, com getters explícitos. Em produção, defina política de normalização consistente para e-mail, SKU e documento. Não registre dados pessoais completos nos logs.

### Serviço de produto

Siga o mesmo contrato: `criar`, `buscarPorId`, `listar`, `atualizar`, `desativar` e, se necessário, `ativar`. O service chama o validator adequado, carrega a entidade, aplica método de domínio, salva e devolve DTO.

### Serviço de pedido

`PedidoService.criar(PedidoCreateRequest)` deve:
1. buscar cliente por ID ou lançar 404;
2. exigir cliente ativo;
3. rejeitar produto repetido na lista;
4. buscar cada produto por ID;
5. exigir produto ativo;
6. copiar o preço vigente do produto para o item;
7. calcular subtotal com `BigDecimal`;
8. somar total;
9. criar pedido com status ABERTO;
10. persistir pedido e itens em uma transação;
11. devolver `PedidoResponse`.

Use `setScale(2, RoundingMode.HALF_UP)` quando a regra de arredondamento exigir escala monetária de duas casas. Não aceite total ou preço unitário enviados pelo cliente.

## 11. Controllers pequenos e focados

Controller trata HTTP. Não deve conter consultas ao repository, regras de preço ou validações de negócio.

Exemplo:

```java
@RestController
@RequestMapping("/api/v1/clientes")
@Validated
public class ClienteController {
    private final ClienteService service;

    public ClienteController(ClienteService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<ClienteResponse> criar(
            @Valid @RequestBody ClienteCreateRequest request) {
        ClienteResponse response = service.criar(request);
        return ResponseEntity
            .created(URI.create("/api/v1/clientes/" + response.id()))
            .body(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClienteResponse> buscar(@PathVariable UUID id) {
        return ResponseEntity.ok(service.buscarPorId(id));
    }

    @GetMapping
    public ResponseEntity<Page<ClienteResponse>> listar(
            @PageableDefault(size = 20, sort = "nome") Pageable pageable) {
        return ResponseEntity.ok(service.listar(pageable));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ClienteResponse> atualizar(
            @PathVariable UUID id,
            @Valid @RequestBody ClienteUpdateRequest request) {
        return ResponseEntity.ok(service.atualizar(id, request));
    }

    @PatchMapping("/{id}/desativacao")
    public ResponseEntity<Void> desativar(@PathVariable UUID id) {
        service.desativar(id);
        return ResponseEntity.noContent().build();
    }
}
```

O `ProdutoController` segue a mesma estrutura em `/api/v1/produtos`. O `PedidoController` deve expor apenas criação, consulta e cancelamento. Não crie um controller genérico para os três recursos.

## 12. Endpoints e contratos HTTP

Base URL local: `http://localhost:8080/api/v1`

### Clientes

| Método | Endpoint | Resultado |
|---|---|---|
| POST | `/clientes` | 201 Created |
| GET | `/clientes/{id}` | 200 OK |
| GET | `/clientes?page=0&size=20&sort=nome,asc` | 200 OK |
| PUT | `/clientes/{id}` | 200 OK |
| PATCH | `/clientes/{id}/desativacao` | 204 No Content |

#### POST /clientes

Payload:

```json
{
  "nome": "Maria da Silva",
  "email": "maria@example.com",
  "documento": "12345678901",
  "telefone": "62999990000"
}
```

Campos gravados: `nome`, `email`, `documento`, `telefone`. O servidor gera `id`, `ativo`, `criadoEm` e `atualizadoEm`.

Resposta 201:

```json
{
  "id": "b7b8c0c1-8f9d-4a0e-a4d8-3a9a7b3b9e10",
  "nome": "Maria da Silva",
  "email": "maria@example.com",
  "documento": "12345678901",
  "telefone": "62999990000",
  "ativo": true,
  "criadoEm": "2026-11-22T12:00:00Z",
  "atualizadoEm": "2026-11-22T12:00:00Z"
}
```

#### PUT /clientes/{id}

Payload completo dos campos editáveis:

```json
{
  "nome": "Maria Silva Atualizado",
  "email": "maria.novo@example.com",
  "documento": "12345678901",
  "telefone": "62988887777"
}
```

Modifica somente `nome`, `email`, `documento`, `telefone` e `atualizadoEm`. `id`, `ativo` e `criadoEm` não podem ser modificados por esse endpoint. PUT representa substituição do conjunto de campos editáveis; campos opcionais ausentes não devem ser interpretados silenciosamente como preservação. Para atualização parcial de dados cadastrais, defina um PATCH específico e documente sua semântica.

#### PATCH /clientes/{id}/desativacao

Sem payload. Modifica `ativo=false` e `atualizadoEm`. Retorna 204. Não remove registros.

### Produtos

| Método | Endpoint | Resultado |
|---|---|---|
| POST | `/produtos` | 201 Created |
| GET | `/produtos/{id}` | 200 OK |
| GET | `/produtos?page=0&size=20` | 200 OK |
| PUT | `/produtos/{id}` | 200 OK |
| PATCH | `/produtos/{id}/desativacao` | 204 No Content |
| PATCH | `/produtos/{id}/ativacao` | 204 No Content |

#### POST /produtos

```json
{
  "nome": "Teclado mecânico",
  "descricao": "Teclado ABNT2",
  "sku": "TEC-001",
  "preco": 249.90
}
```

Grava `nome`, `descricao`, `sku`, `preco`. Servidor gera `id`, `ativo=true` e datas.

#### PUT /produtos/{id}

```json
{
  "nome": "Teclado mecânico RGB",
  "descricao": "Teclado ABNT2 com iluminação",
  "sku": "TEC-001",
  "preco": 279.90
}
```

Modifica `nome`, `descricao`, `sku`, `preco` e `atualizadoEm`. Não modifica `id`, `ativo` ou `criadoEm`. Pedidos anteriores preservam o preço unitário histórico.

#### PATCH de ativação/desativação

Sem payload. Altera somente `ativo` e `atualizadoEm`. A operação deve ser idempotente ou responder com conflito quando a regra de negócio exigir transição estrita; escolha uma política e teste-a.

### Pedidos

| Método | Endpoint | Resultado |
|---|---|---|
| POST | `/pedidos` | 201 Created |
| GET | `/pedidos/{id}` | 200 OK |
| GET | `/pedidos?numero=1001` | 200 OK |
| PATCH | `/pedidos/{id}/cancelamento` | 204 No Content |

#### POST /pedidos

```json
{
  "clienteId": "b7b8c0c1-8f9d-4a0e-a4d8-3a9a7b3b9e10",
  "itens": [
    {
      "produtoId": "e0bba01d-97a5-48b7-a1e7-2efca1f54a21",
      "quantidade": 2
    },
    {
      "produtoId": "d92e8a6f-6d3d-4ac1-9c1b-8fbb5a4e6c2f",
      "quantidade": 1
    }
  ]
}
```

O servidor grava: cliente associado, itens, quantidade, preço unitário vigente no momento da criação, subtotal, total, status ABERTO, número e datas. O cliente **não** envia `numero`, `status`, `precoUnitario`, `subtotal` ou `total`.

Resposta 201 ilustrativa:

```json
{
  "id": "a2a02d7e-5e83-4b30-9d65-2b8f93b1c011",
  "numero": 1001,
  "clienteId": "b7b8c0c1-8f9d-4a0e-a4d8-3a9a7b3b9e10",
  "clienteNome": "Maria da Silva",
  "status": "ABERTO",
  "itens": [
    {
      "produtoId": "e0bba01d-97a5-48b7-a1e7-2efca1f54a21",
      "produtoNome": "Teclado mecânico",
      "sku": "TEC-001",
      "quantidade": 2,
      "precoUnitario": 249.90,
      "subtotal": 499.80
    }
  ],
  "total": 499.80,
  "criadoEm": "2026-11-22T12:10:00Z",
  "atualizadoEm": "2026-11-22T12:10:00Z"
}
```

#### GET /pedidos/{id}

Não altera dados. Devolve cabeçalho, cliente, status, itens e valores históricos.

#### PATCH /pedidos/{id}/cancelamento

Sem payload. Modifica `status=CANCELADO` e `atualizadoEm`. Não apaga itens nem altera os valores históricos. Pedido já cancelado não pode ser cancelado novamente se a política escolhida for transição estrita.

## 13. Exceções e resposta padronizada

Crie exceções próprias:
- `ResourceNotFoundException`: recurso inexistente;
- `ConflictException`: duplicidade ou conflito com estado atual;
- `BusinessException`: regra de negócio não atendida;
- deixe erros inesperados como 500, sem expor stack trace ao cliente.

Formato de erro:

```java
public record ApiErrorResponse(
    Instant timestamp,
    int status,
    String error,
    String message,
    String path,
    Map<String, String> fieldErrors,
    String correlationId
) {}
```

Handler:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    private final MessageSource messageSource;

    public GlobalExceptionHandler(MessageSource messageSource) {
        this.messageSource = messageSource;
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiErrorResponse> notFound(
            ResourceNotFoundException ex, HttpServletRequest request,
            Locale locale) {
        return build(HttpStatus.NOT_FOUND, ex.getMessageKey(),
                     request, locale, Map.of());
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ApiErrorResponse> conflict(
            ConflictException ex, HttpServletRequest request,
            Locale locale) {
        return build(HttpStatus.CONFLICT, ex.getMessageKey(),
                     request, locale, Map.of());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiErrorResponse> validation(
            MethodArgumentNotValidException ex,
            HttpServletRequest request, Locale locale) {
        Map<String, String> fields = new TreeMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
            fields.putIfAbsent(error.getField(),
                messageSource.getMessage(error, locale)));
        return build(HttpStatus.BAD_REQUEST, "erro.validacao",
                     request, locale, fields);
    }

    private ResponseEntity<ApiErrorResponse> build(
            HttpStatus status, String key,
            HttpServletRequest request, Locale locale,
            Map<String, String> fields) {
        String message = messageSource.getMessage(
            key, null, key, locale);
        ApiErrorResponse body = new ApiErrorResponse(
            Instant.now(), status.value(), status.getReasonPhrase(),
            message, request.getRequestURI(), fields,
            (String) request.getAttribute("correlationId"));
        return ResponseEntity.status(status).body(body);
    }
}
```

Adicione handlers para `ConstraintViolationException`, `HttpMessageNotReadableException`, `DataIntegrityViolationException` e `Exception`. O handler genérico deve registrar a exceção completa no log, retornar mensagem genérica e nunca expor SQL, stack trace ou detalhes internos. Para `DataIntegrityViolationException`, converta apenas violações conhecidas de constraints para 409; não transforme todo erro de banco indiscriminadamente em conflito.

Exemplo de erro 400:

```json
{
  "timestamp": "2026-11-22T12:15:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Existem campos inválidos.",
  "path": "/api/v1/clientes",
  "fieldErrors": {
    "email": "Informe um e-mail válido.",
    "nome": "O nome é obrigatório."
  },
  "correlationId": "f30d..."
}
```

Status recomendados:
- 200: consulta/atualização com corpo;
- 201: criação, com `Location`;
- 204: operação sem corpo;
- 400: JSON ou campos inválidos;
- 404: recurso inexistente;
- 409: duplicidade ou conflito de estado;
- 500: falha inesperada.

## 14. Internacionalização com MessageSource

`src/main/resources/messages.properties` (fallback):

```properties
erro.validacao=There are invalid fields.
cliente.nome.obrigatorio=Name is required.
cliente.nome.tamanho=Name must contain between 2 and 120 characters.
cliente.email.obrigatorio=Email is required.
cliente.email.invalido=Enter a valid email address.
cliente.email.duplicado=Email is already registered.
cliente.documento.obrigatorio=Document is required.
cliente.documento.duplicado=Document is already registered.
cliente.nao.encontrado=Customer was not found.
produto.sku.duplicado=SKU is already registered.
produto.preco.positivo=Price must be greater than zero.
pedido.cliente.obrigatorio=Customer is required.
pedido.itens.obrigatorios=At least one item is required.
pedido.cliente.inativo=Customer is inactive.
pedido.produto.inativo=Product is inactive.
pedido.nao.encontrado=Order was not found.
pedido.estado.invalido=Operation is not allowed for the current order status.
```

`messages_pt_BR.properties`:

```properties
erro.validacao=Existem campos inválidos.
cliente.nome.obrigatorio=O nome é obrigatório.
cliente.nome.tamanho=O nome deve conter entre 2 e 120 caracteres.
cliente.email.obrigatorio=O e-mail é obrigatório.
cliente.email.invalido=Informe um e-mail válido.
cliente.email.duplicado=O e-mail já está cadastrado.
cliente.documento.obrigatorio=O documento é obrigatório.
cliente.documento.duplicado=O documento já está cadastrado.
cliente.nao.encontrado=Cliente não encontrado.
produto.sku.duplicado=O SKU já está cadastrado.
produto.preco.positivo=O preço deve ser maior que zero.
pedido.cliente.obrigatorio=O cliente é obrigatório.
pedido.itens.obrigatorios=O pedido deve possuir ao menos um item.
pedido.cliente.inativo=O cliente está inativo.
pedido.produto.inativo=O produto está inativo.
pedido.nao.encontrado=Pedido não encontrado.
pedido.estado.invalido=Operação não permitida para o status atual do pedido.
```

`messages_en.properties` pode conter as mensagens inglesas. Use chaves estáveis nos validators e exceptions, não textos literais. Configure:

```yaml
spring:
  messages:
    basename: messages
    fallback-to-system-locale: false
```

O Spring resolve o idioma por `Accept-Language`, conforme a configuração de locale da aplicação. Teste, por exemplo, `Accept-Language: pt-BR` e `Accept-Language: en`.

## 15. Logs profissionais

Use SLF4J com logger por classe:

```java
private static final Logger log =
    LoggerFactory.getLogger(ClienteServiceImpl.class);
```

Boas práticas:
- `INFO`: início/fim de operações relevantes e eventos de negócio, sem excesso;
- `WARN`: conflito esperado, recurso inexistente quando relevante, tentativa inválida;
- `ERROR`: falha inesperada, com stack trace no servidor;
- `DEBUG`: diagnóstico técnico, desabilitado em produção por padrão;
- use placeholders `{}` em vez de concatenação;
- inclua IDs técnicos e correlation ID;
- nunca registre senha, token, documento completo, payload integral ou dados pessoais desnecessários;
- não registre a mesma exceção em todas as camadas: registre no ponto em que ela é tratada ou no handler final;
- não use `System.out.println`.

Configure níveis:

```yaml
logging:
  level:
    root: INFO
    com.exemplo.vendas: INFO
    org.springframework.web: WARN
    org.hibernate.SQL: WARN
```

Em produção, prefira logs JSON para agregação em ferramentas como ELK, Loki ou CloudWatch. O correlation ID deve ser criado/validado em filtro HTTP e devolvido no header `X-Correlation-Id`. Não confie cegamente em valores externos longos ou com caracteres de controle.

## 16. Configuração PostgreSQL e Docker

`compose.yaml`:

```yaml
services:
  postgres:
    image: postgres:17
    container_name: vendas-postgres
    environment:
      POSTGRES_DB: vendas
      POSTGRES_USER: vendas
      POSTGRES_PASSWORD: ${DB_PASSWORD:-local_dev_password}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U vendas -d vendas"]
      interval: 5s
      timeout: 3s
      retries: 10

volumes:
  postgres_data:
```

A senha padrão é apenas para desenvolvimento local. Em ambiente real, use secret manager/variáveis seguras e não versionadas.

`application.yml`:

```yaml
spring:
  application:
    name: vendas-api
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/vendas}
    username: ${DB_USER:vendas}
    password: ${DB_PASSWORD:local_dev_password}
  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        format_sql: true
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: 8080
```

`ddl-auto: validate`: Hibernate valida o mapeamento, mas não cria/atualiza schema. Flyway é responsável pelas alterações estruturais.

Comandos:

```bash
docker compose up -d
docker compose ps
docker compose logs -f postgres
docker compose down
```

Não use `docker compose down -v` se quiser preservar os dados locais.

### Migration inicial

Crie `src/main/resources/db/migration/V1__create_initial_schema.sql` com:
- tabela `clientes`;
- tabela `produtos`;
- tabela `pedidos`;
- tabela `pedido_itens`;
- primary keys UUID;
- foreign keys;
- unique constraints para e-mail, documento e SKU;
- checks para preço maior que zero, quantidade maior que zero e total não negativo;
- índices para chaves estrangeiras e filtros frequentes.

Exemplo parcial:

```sql
CREATE TABLE clientes (
    id UUID PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL,
    documento VARCHAR(20) NOT NULL,
    telefone VARCHAR(20),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL,
    atualizado_em TIMESTAMPTZ NOT NULL,
    CONSTRAINT uk_clientes_email UNIQUE (email),
    CONSTRAINT uk_clientes_documento UNIQUE (documento)
);

CREATE TABLE produtos (
    id UUID PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    descricao VARCHAR(500),
    sku VARCHAR(40) NOT NULL,
    preco NUMERIC(12,2) NOT NULL CHECK (preco > 0),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL,
    atualizado_em TIMESTAMPTZ NOT NULL,
    CONSTRAINT uk_produtos_sku UNIQUE (sku)
);
```

Complete as tabelas de pedido e itens com FKs e constraints. Garanta que os nomes/estratégias de geração de UUID e número do pedido sejam consistentes entre migrations e entidades. Para número sequencial, use sequence PostgreSQL ou estratégia explícita; não use `count(*) + 1`.

## 17. Testes automatizados

Pirâmide mínima:

1. Testes unitários de validators.
2. Testes unitários de services com Mockito.
3. Testes MVC de controllers com `@WebMvcTest` e MockMvc.
4. Testes de integração de repositories e migrations com Testcontainers PostgreSQL.
5. Testes ponta a ponta dos principais fluxos.

Casos obrigatórios:
- cliente válido cadastrado;
- e-mail duplicado rejeitado;
- documento duplicado rejeitado;
- edição não acusa o próprio e-mail/documento como duplicado;
- cliente inexistente retorna 404;
- produto com preço zero ou negativo rejeitado;
- SKU duplicado rejeitado;
- cliente inativo não cria pedido;
- produto inativo não entra no pedido;
- pedido sem itens rejeitado;
- quantidade zero/negativa rejeitada;
- produto repetido no mesmo pedido rejeitado;
- total calculado pelo servidor;
- alteração posterior do preço do produto não altera pedido antigo;
- pedido cancelado não aceita operação proibida;
- mensagens de erro em português e inglês;
- constraint de unicidade continua protegendo concorrência.

Não use H2 como substituto definitivo dos testes PostgreSQL quando depender de comportamento específico do banco. Testcontainers aproxima o teste do ambiente real.

## 18. Sequência de implementação (passo a passo)

### Etapa 1 — Criar o projeto
- Gerar projeto Maven no Spring Initializr.
- Configurar Java 21.
- Adicionar dependências.
- Executar `mvn clean test`.

**Concluído quando:** aplicação inicia sem erro.

### Etapa 2 — Subir PostgreSQL
- Criar `compose.yaml`.
- Definir variáveis de ambiente.
- Subir banco.
- Confirmar healthcheck.

**Concluído quando:** aplicação consegue abrir conexão com o banco.

### Etapa 3 — Criar migrations
- Criar V1 com as quatro tabelas e constraints.
- Configurar Flyway.
- Configurar Hibernate com `ddl-auto: validate`.

**Concluído quando:** Flyway aplica migration e Hibernate valida as entidades.

### Etapa 4 — Implementar Cliente
- Criar entity e repository.
- Criar DTOs `record`.
- Criar mapper.
- Criar interfaces e implementações dos validators.
- Criar service interface e implementação.
- Criar controller.
- Criar exception handler e mensagens.
- Criar testes.

**Concluído quando:** todos os endpoints de cliente passam nos testes.

### Etapa 5 — Implementar Produto
Repetir a organização de Cliente, aplicando regras de SKU, preço e ativação.

**Concluído quando:** CRUD e validações de produto passam nos testes.

### Etapa 6 — Implementar Pedido
- Criar entidades Pedido e PedidoItem.
- Criar enum StatusPedido.
- Criar DTOs.
- Implementar validações de cliente/produto/itens.
- Implementar cálculo de preço e total no service.
- Criar mapper de resposta.
- Criar controller.
- Criar testes transacionais e de histórico de preço.

**Concluído quando:** pedido é criado com valores calculados no servidor e cancelado conforme as regras.

### Etapa 7 — Qualidade operacional
- Correlation ID.
- Logs por evento.
- Paginação.
- OpenAPI/Swagger.
- Testes de integração com PostgreSQL.
- Verificação de segurança de dados nos logs.

### Etapa 8 — Empacotar e documentar
- Criar Dockerfile multi-stage para API.
- Incluir API no compose, usando `depends_on` com `service_healthy`.
- Documentar variáveis e comandos.
- Criar coleção Postman/Insomnia.
- Executar fluxo completo em ambiente limpo.

## 19. Regras de implementação que não devem ser negociadas

1. Entidade JPA não atravessa a fronteira do controller.
2. Todo endpoint de leitura devolve DTO, nunca entidade.
3. DTOs de entrada e saída são `record`.
4. Não aceitar campos calculados ou controlados pelo servidor no payload.
5. Controller não chama Repository.
6. Repository não contém regra de negócio.
7. Service define a transação e coordena o caso de uso.
8. Validator não persiste dados.
9. Mapper não consulta banco nem calcula total.
10. Validação declarativa e de negócio são complementares.
11. A constraint do banco é a garantia final de unicidade.
12. Mensagens são resolvidas por chave via MessageSource.
13. Valores monetários usam BigDecimal.
14. Pedido guarda preço histórico praticado.
15. Operações compostas de pedido são transacionais.
16. Listagens são paginadas.
17. Logs não contêm credenciais, tokens ou dados pessoais desnecessários.
18. Exceções inesperadas não revelam detalhes internos ao consumidor.
19. Flyway controla o schema; Hibernate apenas valida.
20. Não usar Lombok.

## 20. Exemplos de chamadas com cURL

Cadastrar cliente:

```bash
curl -i -X POST http://localhost:8080/api/v1/clientes \
  -H "Content-Type: application/json" \
  -H "Accept-Language: pt-BR" \
  -d '{
    "nome":"Maria da Silva",
    "email":"maria@example.com",
    "documento":"12345678901",
    "telefone":"62999990000"
  }'
```

Consultar cliente:

```bash
curl -i http://localhost:8080/api/v1/clientes/UUID \
  -H "Accept-Language: pt-BR"
```

Atualizar produto:

```bash
curl -i -X PUT http://localhost:8080/api/v1/produtos/UUID \
  -H "Content-Type: application/json" \
  -d '{
    "nome":"Teclado RGB",
    "descricao":"ABNT2",
    "sku":"TEC-001",
    "preco":279.90
  }'
```

Criar pedido:

```bash
curl -i -X POST http://localhost:8080/api/v1/pedidos \
  -H "Content-Type: application/json" \
  -d '{
    "clienteId":"UUID-DO-CLIENTE",
    "itens":[
      {"produtoId":"UUID-DO-PRODUTO","quantidade":2}
    ]
  }'
```

Cancelar pedido:

```bash
curl -i -X PATCH \
  http://localhost:8080/api/v1/pedidos/UUID/cancelamento
```

Substitua os UUIDs pelos IDs retornados pelas operações de cadastro.

## 21. Critérios de aceite

O projeto estará concluído quando:

- [ ] API inicia com configuração documentada.
- [ ] PostgreSQL sobe via Docker Compose.
- [ ] Flyway cria e versiona o schema.
- [ ] CRUD de clientes funciona com DTOs `record`.
- [ ] CRUD de produtos funciona com DTOs `record`.
- [ ] Criação e consulta de pedidos funcionam.
- [ ] Cancelamento respeita o estado do pedido.
- [ ] Nenhum controller devolve entidade JPA.
- [ ] Controllers não possuem regras de negócio.
- [ ] Services possuem transações adequadas.
- [ ] Validators possuem interfaces e testes.
- [ ] Bean Validation funciona em requests aninhados.
- [ ] MapStruct converte entidades e DTOs.
- [ ] Mensagens funcionam em pelo menos pt-BR e en.
- [ ] Exception handler retorna formato padronizado.
- [ ] Logs têm correlation ID e não expõem dados sensíveis.
- [ ] Testes unitários, MVC e integração passam.
- [ ] Swagger descreve endpoints, payloads e respostas.
- [ ] README e comandos permitem reproduzir o ambiente.

## 22. Como executar

1. Configure Docker e Java 21.
2. Copie `.env.example` para `.env` e ajuste a senha local.
3. Suba o banco: `docker compose up -d`.
4. Execute os testes: `./mvnw clean verify`.
5. Inicie a API: `./mvnw spring-boot:run`.
6. Acesse Swagger: `http://localhost:8080/swagger-ui/index.html`.
7. Consulte OpenAPI: `http://localhost:8080/v3/api-docs`.

No Windows PowerShell, use `.\mvnw.cmd clean verify` e `.\mvnw.cmd spring-boot:run`.

## 23. Evoluções recomendadas após o escopo inicial

- Spring Security com JWT e controle de permissões;
- estoque e reserva de itens;
- fluxo de aprovação de pedidos;
- pagamentos e estornos;
- auditoria de alterações;
- outbox pattern e mensageria;
- observabilidade com Actuator, Micrometer, Prometheus e Grafana;
- rate limiting;
- versionamento e política de compatibilidade da API.

Essas funcionalidades devem entrar em etapas próprias, com requisitos, modelo de dados, regras, testes e documentação separados.