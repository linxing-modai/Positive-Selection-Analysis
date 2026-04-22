#!/bin/bash
# 基因正选择分析流程

# 1. 准备CDS序列比对
# 输入：CDS序列文件
# 输出：codon-aware比对

align_cds() {
    local input=$1
    local output=$2
    
    # 使用PRANK或MACSE进行codon比对
    macse -prog alignSequences \
        -seq ${input} \
        -out_NT ${output}_NT.fasta \
        -out_AA ${output}_AA.fasta
}

# 2. 计算Ka/Ks
calculate_kaks() {
    local alignment=$1
    local output=$2
    
    # 使用KaKs_Calculator
    KaKs_Calculator -i ${alignment} \
        -o ${output} \
        -m YN
}

# 3. PAML codeml分析
run_paml() {
    local alignment=$1
    local tree=$2
    local output_dir=$3
    
    mkdir -p ${output_dir}
    
    # 创建codeml控制文件
    cat > ${output_dir}/codeml.ctl <<EOF
      seqfile = ${alignment}
     treefile = ${tree}
      outfile = ${output_dir}/results.txt
        noisy = 3
      verbose = 1
      runmode = 0
      seqtype = 1
    CodonFreq = 2
        model = 0
      NSsites = 0 1 2 7 8
        icode = 0
    fix_omega = 0
        omega = 0.5
EOF
    
    cd ${output_dir}
    codeml codeml.ctl
    cd -
}

# 4. 批量处理多个基因
batch_analysis() {
    local gene_dir=$1
    local tree=$2
    local output_base=$3
    
    for gene in ${gene_dir}/*.fasta; do
        gene_name=$(basename ${gene} .fasta)
        echo "Processing ${gene_name}..."
        
        # 比对
        align_cds ${gene} ${output_base}/${gene_name}_aligned
        
        # Ka/Ks
        calculate_kaks ${output_base}/${gene_name}_aligned_NT.fasta \
            ${output_base}/${gene_name}_kaks.txt
        
        # PAML
        run_paml ${output_base}/${gene_name}_aligned_NT.fasta \
            ${tree} \
            ${output_base}/${gene_name}_paml
    done
}

# 使用示例
# batch_analysis ./cds_sequences ./species.tree ./results
