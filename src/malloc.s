# 5.1 implemente o algoritmo proposto na seção 5.1.2 em assembly
.section    .data
    topoInicialHeap:  .quad 0
.section    .text
###################################################################################################################
###################################################################################################################
# void iniciaAlocador() Executa syscall brk para obter o endereco do topo corrente da heap e o armazena em uma
# variavel global, topoInicialHeap.
###################################################################################################################
###################################################################################################################
iniciaAlocador:
    pushq       %rbp                    # Empilha endereco-base do registro de ativacao antigo
    movq        %rsp, %rbp              # Atualiza ponteiro para endereco-base do registro de ativacao atual
    movq        $12, %rax               # ID do servico brk
    movq        $0, %rdi                # Parametro da chamada (de modo a retornar a altura atual da brk)
    syscall                             # Chamada ao sistema
    movq        %rax, topoInicialHeap   # Armazena altura da brk em topoInicialHeap
    movq        $0, (%rax)              # Indica que o "bloco" esta livre
    popq        %rbp                    # Desmonta registro de ativacao atual e restaura ponteiro para o antigo
    ret                                 # Retorna
###################################################################################################################
###################################################################################################################
# void finalizaAlocador() Executa syscall brk para restaurar o valor original da heap contido em topoInicialHeap.
###################################################################################################################
###################################################################################################################
finalizaAlocador:
    pushq       %rbp                    # Empilha endereco-base do registro de ativacao antigo
    movq        %rsp, %rbp              # Atualiza ponteiro para endereco-base do registro de ativacao atual
    movq        $12, %rax               # ID do servico brk
    movq        $topoInicialHeap, %rdi  # Parametro da chamada (de modo a atualizar a altura da brk)
    syscall                             # Chamada ao sistema
    popq        %rbp                    # Desmonta registro de ativacao atual e restaura ponteiro para o antigo
    ret                                 # Retorna
###################################################################################################################
###################################################################################################################
# int liberaMem(void* bloco) indica que o bloco esta livre. (int?????????????????????????????????????????????????)
###################################################################################################################
###################################################################################################################
liberaMem:
    pushq       %rbp                    # Empilha endereco-base do registro de ativacao antigo
    movq        %rsp, %rbp              # Atualiza ponteiro para endereco-base do registro de ativacao atual
    movq        $0, -16(%rdi)           # Indica que o bloco esta livre
    popq        %rbp                    # Desmonta registro de ativacao atual e restaura ponteiro para o antigo
    ret                                 # Retorna
###################################################################################################################
###################################################################################################################
# void* alocaMem(int num_bytes)
### 1. Procura um bloco livre com tamanho maior ou igual a num_bytes.
### 2. Se encontrar, indica que o bloco esta ocupado e retorna o endereco inicial do bloco;
### 3. Se nao encontrar, abre espaco para um novo bloco usando a syscall brk, indica que o bloco esta ocupado e
### retorna o endereco inicial do bloco.
###################################################################################################################
###################################################################################################################
alocaMem:
    pushq       %rbp                    # Empilha endereco-base do registro de ativacao antigo
    movq        %rsp, %rbp              # Atualiza ponteiro para endereco-base do registro de ativacao atual
    movq        $topoInicialHeap, %rax  # Obtem topoInicialHeap
    pushq       %rax                    # Aloca variavel local que aponta para a primeira informacao gerencial
  loop:
    movq        -8(%rbp), %rax          # Obtem ponteiro para informacao gerencial do bloco atual
    movq        $topoInicialHeap, %rbx  # Obtem topoInicialHeap
    cmpq        %rax, %rbx              # Compara topoInicialHeap com ponteiro para informacao gerencial atual
    jle         done_loop_miss          # Se nao ha blocos liberados utilizaveis, sai do laco com status "miss"
    movq        -8(%rbp), %rax          # Obtem ponteiro para informacao gerencial do bloco atual
    movq        (%rax), %rax            # Obtem informacao gerencial do bloco atual
    movq        $0, %rbx                # Obtem 0 (que indica "livre")
    cmpq        %rax, %rbx              # Compara 0 com informacao gerencial do bloco atual
    jne         do_loop_stuff           # Se o bloco nao esta livre, continua no laco
    movq        -8(%rbp), %rax          # Obtem ponteiro para informacao gerencial do bloco atual
    movq        8(%rax), %rax           # Obtem tamanho do bloco atual
    movq        16(%rbp), %rbx          # Obtem parametro num_bytes
    cmpq        %rax, %rbx              # Compara num_bytes com tamanho do bloco atual
    jle         done_loop_hit           # Se o bloco atual e grande o suficiente, sai do laco com status "hit"
  do_loop_stuff:
    movq        -8(%rbp), %rax          # Obtem ponteiro para informacao gerencial do bloco atual
    movq        8(%rax), %rbx          # Obtem tamanho do bloco atual
    addq        $16, %rax               # Obtem ponteiro para inicio do bloco atual
    addq        $rbx, %rax              # Obtem ponteiro para a proxima informacao gerencial
    movq        %rax, -8(%rbp)          # Atualiza variavel com ponteiro para proxima informacao gerencial
    jmp         loop                    # Continua no laco
  done_loop_hit:
    movq        -8(%rbp), %rax          # Obtem ponteiro para informacao gerencial
    movq        8(%rax), %rax           # Obtem tamanho do bloco
    movq        16(%rbp), %rbx          # Obtem parametro num_bytes
    cmpq        %rax, %rbx              # Compara num_bytes com tamanho do bloco
    je          done                    # Se o bloco tem o tamanho certo, desvia para o fim da funcao
    movq        -8(%rbp), %rax          # Obtem ponteiro para informacao gerencial
    movq        16(%rbp), %rbx          # Obtem parametro num_bytes
    movq        8(%rax), %rdi           # Obtem tamanho do bloco
    subq        %rbx, %rdi              # Subtrai tamanho a ser alocado
    subq        $16, %rdi               # Subtrai espaco ocupado pelas informacoes gerenciais
    addq        %rbx, %rax              # Obtem ponteiro para final do bloco a ser alocado e inicio do bloco livre restante
    movq        $0, %rax                # Indica que o bloco restante esta livre
    movq        %rdi, 8(%rax)           # Estabelece tamanho do bloco restante
    jmp         done                    # Desvia para o final da funcao
  done_loop_miss:
    movq        16(%rbp), %rax          # Obtem parametro num_bytes
    movq        -8(%rbp), %rbx          # Obtem ponteiro para topo atual da heap
    addq        $16, %rbx               # Obtem ponteiro para inicio do bloco a ser alocado
    addq        %rax, %rbx              # Obtem ponteiro para final do bloco a ser alocado
    movq        $12, %rax               # ID do servico brk
    movq        %rbx, %rdi              # Parametro da chamada (de modo a atualizar a altura da brk)
    syscall                             # Chamada ao sistema
  done:
    movq        -8(%rbp), %rax          # Obtem ponteiro para informacao gerencial alocada
    movq        $1, (%rax)              # Indica que o bloco alocado esta ocupado
    addq        $8, %rax                # Obtem ponteiro para tamanho do bloco alocado
    movq        16(%rbp), %rbx          # Obtem parametro num_bytes
    movq        %rbx, (%rax)            # Estabelece tamanho do bloco alocado
    addq        $8, %rax                # Obtem ponteiro para bloco alocado
    movq        %rax, %rdi              # Estabelece ponteiro para bloco alocado como valor de retorno
    addq        $8, %rsp                # Desempilha variavel local
    popq        %rbp                    # Desmonta registro de ativacao atual e restaura ponteiro para o antigo
    ret                                 # Retorna
###################################################################################################################
###################################################################################################################