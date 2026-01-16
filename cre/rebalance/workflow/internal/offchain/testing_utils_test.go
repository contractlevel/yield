package offchain

import (
	"bytes"
	"compress/gzip"
	"context"

	"github.com/smartcontractkit/chainlink-protos/cre/go/sdk"
	"github.com/smartcontractkit/cre-sdk-go/capabilities/networking/http"
	"google.golang.org/protobuf/types/known/anypb"
)

// Shared Mock
type mockHttpCapability struct {
	id string
	fn func(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse
}

func (m *mockHttpCapability) ID() string { return m.id }
func (m *mockHttpCapability) Invoke(ctx context.Context, req *sdk.CapabilityRequest) *sdk.CapabilityResponse {
	return m.fn(ctx, req)
}

// Shared Helper to create a success response
func MockResponse(statusCode uint32, body []byte) *sdk.CapabilityResponse {
	respAny, _ := anypb.New(&http.Response{StatusCode: statusCode, Body: body})
	return &sdk.CapabilityResponse{Response: &sdk.CapabilityResponse_Payload{Payload: respAny}}
}

// Helper to compress JSON for the Gzip test case
func compressGzip(data string) []byte {
	var buf bytes.Buffer
	gz := gzip.NewWriter(&buf)
	gz.Write([]byte(data))
	gz.Close()
	return buf.Bytes()
}
