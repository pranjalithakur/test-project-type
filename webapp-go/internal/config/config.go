package config

import (
	"os"

	"gopkg.in/yaml.v2"
)

type Config struct {
	Port     string `yaml:"port"`
	DBDriver string `yaml:"db_driver"`
	DBDSN    string `yaml:"db_dsn"`
	Secret   string `yaml:"secret"`
}

func Load(filename string) (*Config, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}
