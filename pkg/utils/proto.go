package utils

import (
	"github.com/ghodss/yaml"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/reflect/protoreflect"
)

// ProtoToYAML converts a Proto message to it's YAML representation in bytes
func ProtoToYAML(m protoreflect.ProtoMessage) ([]byte, error) {
	marshalOptions := protojson.MarshalOptions{
		UseProtoNames: true,
	}
	configJSON, err := marshalOptions.Marshal(m)
	if err != nil {
		log.Error().Err(err).Msg("Error marshaling proto to JSON")
		return nil, err
	}

	configYAML, err := yaml.JSONToYAML(configJSON)
	if err != nil {
		log.Error().Err(err).Msgf("Error converting JSON to YAML")
		return nil, err
	}
	return configYAML, err
}
