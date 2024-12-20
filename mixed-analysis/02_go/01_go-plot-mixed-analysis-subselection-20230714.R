# GO plot using subset of GO terms selected from go-figure analysis and manual 
# selection (By Alice and Brenda). Go terms are ordered manually
# Code written by ejr
# Adapted by Brenda Pardo
# 2023-05-15

#Libraries
library(openxlsx)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(RColorBrewer)
library(ggplot2)
library(cowplot)
library(purrr)
library(here)


#Load data
go<- read.xlsx(here("mixed-analysis/02_go/20230706_GO_id_fc0-selection-Combined-AAI.xlsx"))


#List of tresholds
thresholds <- c(0)

#Plot order
plot_order <- c(
  "1dpa-intact",
  "3dpa-1dpa",
  "6dpa-1dpa",
  "9dpa-1dpa",
  "12dpa-1dpa",
  "15dpa-1dpa",
  "21dpa-1dpa",
  "28dpa-1dpa",
  "intact-1dpa"
)

  
  go<- as.data.frame(go) %>%
    select(go_id, order) %>%
    na.omit()
  
#lfc
  x=0
    
    # read in GO enrichment INTACT VS 1 <- to use as first timepoint
    go.br.int_1dpa <- read_tsv(here(paste0("intact-reference/03_go/output/go-breakdown_lfc", x, ".txt.gz"))) %>%
      filter(cluster=="de-up-go_s_1dpa-s_intact-intact-ref_lfc0.txt.gz") 
    
    # read in GO enrichment vs 1dpa all comparisons
    go.br.vs1 <- read_tsv(here(paste0("1dpa-reference/03_go/output/go-breakdown_lfc", x, ".txt.gz")))
    
    go.br<- rbind(go.br.int_1dpa, go.br.vs1)
    
    go.br2 <- go.br %>%
      mutate(file=cluster) %>%
      filter(str_detect(file, "de-up")) %>%
      dplyr::rename(go_id = ID) %>%
      mutate(file = str_replace(file, "de-", "")) %>%
      mutate(file = str_replace(file, "-go_s", "")) %>%
      mutate(file = str_replace(file, "-s_", "-")) %>%
      mutate(file = str_replace(file, ".txt.gz", "")) %>%
      mutate(file = ifelse(str_detect(file, "-1dpa-ref_lfc"), 
                           str_replace(file, "-1dpa-ref_lfc", "_lfc_"), str_replace(file, "-intact-ref_lfc", "_lfc_"))) %>%
      separate(file, c("direction", "timepoint","none", "lfc"), sep="_")
    
    label_levels <-   go.br2 %>%
      left_join(go) %>%
      filter(! is.na(order)) %>%
      mutate(label = paste0(go_id, ": ", Description)) %>%
      rowwise() %>%
      mutate(label2 = Description)%>%
      filter(direction == "up") %>%
      select(label, label2, order) %>%
      distinct() %>%
      arrange(dplyr::desc(order))

    
    go_fig <- go.br2 %>%
      left_join(go) %>%
      filter(! is.na(order)) %>%
      mutate(label = paste0(go_id, ": ", Description)) %>%
      mutate(label = factor(label, levels=label_levels$label)) %>%
      rowwise() %>%
      mutate(label2 = Description) %>%
      mutate(label2 = factor(label2, levels=label_levels$label2)) %>%
      filter(direction == "up") %>%
      mutate(`-log10(pval)` = log10(p.adjust) * -1) %>%
      dplyr::rename(`# genes` = Count)
    
    
    mypalette<-rev(brewer.pal(11,"RdBu"))
    lim <- c(max(abs(go_fig$`-log10(pval)`)) * -1, max(abs(go_fig$`-log10(pval)`)))
    
    p2<- ggplot(data = go_fig, aes(x = factor(timepoint, levels=plot_order), y = label, size = `# genes`, )) +
      theme_cowplot() +
      geom_hline(aes(yintercept = label), alpha = .1) +
      geom_point() + 
      scale_size(range=c(2,14)) +
      xlab("") +
      ylab("") +
      theme(axis.text.x = element_text(angle = 45, vjust = 1.1, hjust=1.1)) +
      scale_x_discrete(limits = plot_order)
    
    ggsave(here(paste0("mixed-analysis/02_go/figures/GO_id_fc", x, "-selection-subselection-20230714.pdf")),p2, height=10, width=11.5)
    
    
    
    p3 <- ggplot(data = go_fig, aes(x = factor(timepoint, levels=plot_order), y = label2, size = `# genes`)) +
      theme_cowplot() +
      geom_hline(aes(yintercept = label), alpha = .1) +
      geom_point() +
      scale_size(range=c(2,14)) +  
      xlab("") +
      ylab("") +
      theme(axis.text.x = element_text(angle = 45, vjust = 1.1, hjust=1.1))+
      scale_x_discrete(limits = plot_order)
    
    ggsave(here(paste0("mixed-analysis/02_go/figures/GO_noid_fc", x, "-selection-subselection-20230714.pdf")), p3, height=10, width=10.5)
    

