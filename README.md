#Personalized Probabilistic Health Search
This repository contains the source code, which was used to conduct the
experiments that evaluated the Personalized Probabilistic Health Search (PPHS)
model. This model was developed in the diploma thesis _Using health statistics to improve medical and health search_ by Tawan Sierek.
An overview of the goals and results can be looked up in the poster presentation [poster.pdf](poster.pdf).

##Experiments

We employed two evaluation suites that were used in:
* [the Clinical Decision Support Track (CDS 2014)](http://trec-cds.appspot.com/2014.html),
* [the ShARe/CLEF eHealth Evaluation Lab 2014 Task 3 (CLEF 2014)](http://clefehealth2014.dcu.ie/task-3).

We evaluated 12 runs in both evaluation suites, CDS 2014 and CLEF 2014. Seven runs were dedicated establishing a strong baseline for each test collection and its test queries. Five runs were conducted with the PPHS improvement and variants of it.




##Experimental Setup
The following figure depecits the general archtictecture.
![Alt text](/figures/arch.png?raw=true "Optional Title")


##How to reprduce
This is a step by step guide for setting up the experiments.

###Prerequisites
* A unix like OS (any Linux Distribution, Mac OS, etc..)
* [Apache Solr 4.10.2](http://lucene.apache.org/solr/)
* [Ruby 2.1.1](https://www.ruby-lang.org)
* [PostgreSQL 9.4.0](http://www.postgresql.org/)
* [Java 1.8](https://java.com/en/download/) 
```
gem install bundle
bundle install
```
