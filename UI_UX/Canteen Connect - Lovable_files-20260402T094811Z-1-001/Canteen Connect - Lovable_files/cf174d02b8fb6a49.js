;!function(){try { var e="undefined"!=typeof globalThis?globalThis:"undefined"!=typeof global?global:"undefined"!=typeof window?window:"undefined"!=typeof self?self:{},n=(new e.Error).stack;n&&((e._debugIds|| (e._debugIds={}))[n]="c329c6fb-555d-0d18-f705-9473567eaefb")}catch(e){}}();
(globalThis.TURBOPACK||(globalThis.TURBOPACK=[])).push(["object"==typeof document?document.currentScript:void 0,6182,e=>{"use strict";var t=e.i(606755),n=e.i(292906),r=e.i(838248);function a(){let e=(0,t.useProjectStore)(e=>e.project),a=e?.supabase_project_config,o=(0,n.useSupabaseOrganizations)({workspaceId:e?.workspace_id??""}),{selectedInstance:i}=(0,t.useSelectedCloudInstance)(),{supabaseIntegrationData:s}=(0,r.useSupabaseIntegrationData)(e?.id),l=!!e?.supabase_project_config?.supabase_project_id,c=s?.[i]?.supabase_project_id??null;c||(c=e?.supabase_project_config?.supabase_project_id??null);let u=function(e,t){if(e.isLoading||!t||!e.supabaseOrganizations)return!1;if(e.noOrganizations)return!0;let n=e.supabaseOrganizations.find(e=>e.id===t);return!n||"connected"!==n.status}(o,l?a?.supabase_organization_id??null:s?.[i]?.supabase_organization_id??null),d=o.supabaseOrganizations?.flatMap(e=>e.projects||[]);return!u&&d&&c&&d.find(e=>e.id===c)||null}e.s(["useConnectedSupabaseProject",()=>a],6182)},974982,167731,e=>{"use strict";var t=e.i(418883),n=e.i(69235),r=e.i(334435),a=e.i(488868);let o=/\{[^{}]+\}/g;function i(e,t,n){if(null==t)return"";if("object"==typeof t)throw Error("Deeply-nested arrays/objects aren’t supported. Provide your own `querySerializer()` to handle these.");return`${e}=${n?.allowReserved===!0?t:encodeURIComponent(t)}`}function s(e,t,n){if(!t||"object"!=typeof t)return"";let r=[],a={simple:",",label:".",matrix:";"}[n.style]||"&";if("deepObject"!==n.style&&!1===n.explode){for(let e in t)r.push(e,!0===n.allowReserved?t[e]:encodeURIComponent(t[e]));let a=r.join(",");switch(n.style){case"form":return`${e}=${a}`;case"label":return`.${a}`;case"matrix":return`;${e}=${a}`;default:return a}}for(let a in t){let o="deepObject"===n.style?`${e}[${a}]`:a;r.push(i(o,t[a],n))}let o=r.join(a);return"label"===n.style||"matrix"===n.style?`${a}${o}`:o}function l(e,t,n){if(!Array.isArray(t))return"";if(!1===n.explode){let r={form:",",spaceDelimited:"%20",pipeDelimited:"|"}[n.style]||",",a=(!0===n.allowReserved?t:t.map(e=>encodeURIComponent(e))).join(r);switch(n.style){case"simple":return a;case"label":return`.${a}`;case"matrix":return`;${e}=${a}`;default:return`${e}=${a}`}}let r={simple:",",label:".",matrix:";"}[n.style]||"&",a=[];for(let r of t)"simple"===n.style||"label"===n.style?a.push(!0===n.allowReserved?r:encodeURIComponent(r)):a.push(i(e,r,n));return"label"===n.style||"matrix"===n.style?`${r}${a.join(r)}`:a.join(r)}function c(e){return function(t){let n=[];if(t&&"object"==typeof t)for(let r in t){let a=t[r];if(null!=a){if(Array.isArray(a)){if(0===a.length)continue;n.push(l(r,a,{style:"form",explode:!0,...e?.array,allowReserved:e?.allowReserved||!1}));continue}if("object"==typeof a){n.push(s(r,a,{style:"deepObject",explode:!0,...e?.object,allowReserved:e?.allowReserved||!1}));continue}n.push(i(r,a,e))}}return n.join("&")}}function u(e,t){return e instanceof FormData?e:t&&"application/x-www-form-urlencoded"===(t.get instanceof Function?t.get("Content-Type")??t.get("content-type"):t["Content-Type"]??t["content-type"])?new URLSearchParams(e).toString():JSON.stringify(e)}function d(...e){let t=new Headers;for(let n of e)if(n&&"object"==typeof n)for(let[e,r]of n instanceof Headers?n.entries():Object.entries(n))if(null===r)t.delete(e);else if(Array.isArray(r))for(let n of r)t.append(e,n);else void 0!==r&&t.set(e,r);return t}function p(e){return e.endsWith("/")?e.substring(0,e.length-1):e}var m=e.i(48105),f=e.i(606755);e.i(767460);var y=e.i(64244),_=e.i(872669),g=e.i(264337),E=e.i(929883);e.i(598654);var h=e.i(653544),b=function(){function e(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}return function(t,n,r){return n&&e(t.prototype,n),r&&e(t,r),t}}(),S=Object.freeze(Object.defineProperties(["",""],{raw:{value:Object.freeze(["",""])}})),A=function(){function e(){for(var t=this,n=arguments.length,r=Array(n),a=0;a<n;a++)r[a]=arguments[a];if(!(this instanceof e))throw TypeError("Cannot call a class as a function");return this.tag=function(e){for(var n=arguments.length,r=Array(n>1?n-1:0),a=1;a<n;a++)r[a-1]=arguments[a];return"function"==typeof e?t.interimTag.bind(t,e):"string"==typeof e?t.transformEndResult(e):(e=e.map(t.transformString.bind(t)),t.transformEndResult(e.reduce(t.processSubstitutions.bind(t,r))))},r.length>0&&Array.isArray(r[0])&&(r=r[0]),this.transformers=r.map(function(e){return"function"==typeof e?e():e}),this.tag}return b(e,[{key:"interimTag",value:function(e,t){for(var n=arguments.length,r=Array(n>2?n-2:0),a=2;a<n;a++)r[a-2]=arguments[a];return this.tag(S,e.apply(void 0,[t].concat(r)))}},{key:"processSubstitutions",value:function(e,t,n){var r=this.transformSubstitution(e.shift(),t);return"".concat(t,r,n)}},{key:"transformString",value:function(e){return this.transformers.reduce(function(e,t){return t.onString?t.onString(e):e},e)}},{key:"transformSubstitution",value:function(e,t){return this.transformers.reduce(function(e,n){return n.onSubstitution?n.onSubstitution(e,t):e},e)}},{key:"transformEndResult",value:function(e){return this.transformers.reduce(function(e,t){return t.onEndResult?t.onEndResult(e):e},e)}}]),e}();let R=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:"";return{onEndResult:function(t){if(""===e)return t.trim();if("start"===(e=e.toLowerCase())||"left"===e)return t.replace(/^\s*/,"");if("end"===e||"right"===e)return t.replace(/\s*$/,"");throw Error("Side not supported: "+e)}}},N=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:"initial";return{onEndResult:function(t){if("initial"===e){var n=t.match(/^[^\S\n]*(?=\S)/gm),r=n&&Math.min.apply(Math,function(e){if(!Array.isArray(e))return Array.from(e);for(var t=0,n=Array(e.length);t<e.length;t++)n[t]=e[t];return n}(n.map(function(e){return e.length})));if(r){var a=RegExp("^.{"+r+"}","gm");return t.replace(a,"")}return t}if("all"===e)return t.replace(/^[^\S\n]+/gm,"");throw Error("Unknown type: "+e)}}},w=function(e,t){return{onEndResult:function(n){if(null==e||null==t)throw Error("replaceResultTransformer requires at least 2 arguments.");return n.replace(e,t)}}},T=function(e,t){return{onSubstitution:function(n,r){if(null==e||null==t)throw Error("replaceSubstitutionTransformer requires at least 2 arguments.");return null==n?n:n.toString().replace(e,t)}}};var O={separator:"",conjunction:"",serial:!1};let j=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:O;return{onSubstitution:function(t,n){if(Array.isArray(t)){var r=t.length,a=e.separator,o=e.conjunction,i=e.serial,s=n.match(/(\n?[^\S\n]+)$/);if(t=s?t.join(a+s[1]):t.join(a+" "),o&&r>1){var l=t.lastIndexOf(a);t=t.slice(0,l)+(i?a:"")+" "+o+t.slice(l+1)}}return t}}},v=function(e){return{onSubstitution:function(t,n){if(null!=e&&"string"==typeof e)"string"==typeof t&&t.includes(e)&&(t=t.split(e));else throw Error("You need to specify a string character to split by.");return t}}};var C=function(e){return null!=e&&!Number.isNaN(e)&&"boolean"!=typeof e};new A(j({separator:","}),N,R),new A(j({separator:",",conjunction:"and"}),N,R),new A(j({separator:",",conjunction:"or"}),N,R),new A(v("\n"),function(){return{onSubstitution:function(e){return Array.isArray(e)?e.filter(C):C(e)?e:""}}},j,N,R),new A(v("\n"),j,N,R,T(/&/g,"&amp;"),T(/</g,"&lt;"),T(/>/g,"&gt;"),T(/"/g,"&quot;"),T(/'/g,"&#x27;"),T(/`/g,"&#x60;")),new A(w(/(?:\n(?:\s*))+/g," "),R),new A(w(/(?:\n\s*)/g,""),R),new A(j({separator:","}),w(/(?:\s+)/g," "),R),new A(j({separator:",",conjunction:"or"}),w(/(?:\s+)/g," "),R),new A(j({separator:",",conjunction:"and"}),w(/(?:\s+)/g," "),R),new A(j,N,R),new A(j,w(/(?:\s+)/g," "),R);var I=new A(N,R);new A(N("all"),R);let D=`
-- Adapted from information_schema.columns

SELECT
  c.oid :: int8 AS table_id,
  nc.nspname AS schema,
  c.relname AS table,
  (c.oid || '.' || a.attnum) AS id,
  a.attnum AS ordinal_position,
  a.attname AS name,
  CASE
    WHEN a.atthasdef THEN regexp_replace(pg_get_expr(ad.adbin, ad.adrelid), '::[a-zA-Z0-9_ ]+$', '')
    ELSE NULL
  END AS default_value,
  CASE
    WHEN t.typtype = 'd' THEN CASE
      WHEN bt.typelem <> 0 :: oid
      AND bt.typlen = -1 THEN 'ARRAY'
      WHEN nbt.nspname = 'pg_catalog' THEN format_type(t.typbasetype, NULL)
      ELSE 'USER-DEFINED'
    END
    ELSE CASE
      WHEN t.typelem <> 0 :: oid
      AND t.typlen = -1 THEN 'ARRAY'
      WHEN nt.nspname = 'pg_catalog' THEN format_type(a.atttypid, NULL)
      ELSE 'USER-DEFINED'
    END
  END AS data_type,
  COALESCE(bt.typname, t.typname) AS format,
  a.attidentity IN ('a', 'd') AS is_identity,
  CASE
    a.attidentity
    WHEN 'a' THEN 'ALWAYS'
    WHEN 'd' THEN 'BY DEFAULT'
    ELSE NULL
  END AS identity_generation,
  a.attgenerated IN ('s') AS is_generated,
  NOT (
    a.attnotnull
    OR t.typtype = 'd' AND t.typnotnull
  ) AS is_nullable,
  (
    c.relkind IN ('r', 'p')
    OR c.relkind IN ('v', 'f') AND pg_column_is_updatable(c.oid, a.attnum, FALSE)
  ) AS is_updatable,
  uniques.table_id IS NOT NULL AS is_unique,
  check_constraints.definition AS "check",
  array_to_json(
    array(
      SELECT
        enumlabel
      FROM
        pg_catalog.pg_enum enums
      WHERE
        enums.enumtypid = coalesce(bt.oid, t.oid)
        OR enums.enumtypid = coalesce(bt.typelem, t.typelem)
      ORDER BY
        enums.enumsortorder
    )
  ) AS enums,
  col_description(c.oid, a.attnum) AS comment
FROM
  pg_attribute a
  LEFT JOIN pg_attrdef ad ON a.attrelid = ad.adrelid
  AND a.attnum = ad.adnum
  JOIN (
    pg_class c
    JOIN pg_namespace nc ON c.relnamespace = nc.oid
  ) ON a.attrelid = c.oid
  JOIN (
    pg_type t
    JOIN pg_namespace nt ON t.typnamespace = nt.oid
  ) ON a.atttypid = t.oid
  LEFT JOIN (
    pg_type bt
    JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid
  ) ON t.typtype = 'd'
  AND t.typbasetype = bt.oid
  LEFT JOIN (
    SELECT DISTINCT ON (table_id, ordinal_position)
      conrelid AS table_id,
      conkey[1] AS ordinal_position
    FROM pg_catalog.pg_constraint
    WHERE contype = 'u' AND cardinality(conkey) = 1
  ) AS uniques ON uniques.table_id = c.oid AND uniques.ordinal_position = a.attnum
  LEFT JOIN (
    -- We only select the first column check
    SELECT DISTINCT ON (table_id, ordinal_position)
      conrelid AS table_id,
      conkey[1] AS ordinal_position,
      substring(
        pg_get_constraintdef(pg_constraint.oid, true),
        8,
        length(pg_get_constraintdef(pg_constraint.oid, true)) - 8
      ) AS "definition"
    FROM pg_constraint
    WHERE contype = 'c' AND cardinality(conkey) = 1
    ORDER BY table_id, ordinal_position, oid asc
  ) AS check_constraints ON check_constraints.table_id = c.oid AND check_constraints.ordinal_position = a.attnum
WHERE
  NOT pg_is_other_temp_schema(nc.oid)
  AND a.attnum > 0
  AND NOT a.attisdropped
  AND (c.relkind IN ('r', 'v', 'm', 'f', 'p'))
  AND (
    pg_has_role(c.relowner, 'USAGE')
    OR has_column_privilege(
      c.oid,
      a.attnum,
      'SELECT, INSERT, UPDATE, REFERENCES'
    )
  )
`,L=`
SELECT
    schemaname AS schema,
    relname AS name,
    n_live_tup AS live_rows_estimate
FROM
    pg_stat_user_tables
ORDER BY
    schemaname,
    relname
`,q=["information_schema","pg_catalog","pg_toast","_timescaledb_internal"];function $(e=[]){let t="",n=D+(t=e.length>0?`AND nc.nspname in (${e.map(e=>`'${e}'`).join(",")})`:`AND nc.nspname not in (${q.map(e=>`'${e}'`).join(",")})`),r=I`
    with
      tables as (${L}),
      columns as (${n}),
      table_columns as (
        select
          t.*,
          coalesce(
            json_agg(
              json_build_object(
                'name', c.name,
                'data_type', c.data_type,
                'is_nullable', c.is_nullable,
                'default_value', c.default_value,
                'ordinal_position', c.ordinal_position
              ) order by c.ordinal_position
            ) filter (where c.name is not null),
            '[]'::json
          ) as columns
        from tables t
        left join columns c on c.schema = t.schema and c.table = t.name
        group by t.schema, t.name, t.live_rows_estimate
      )
    select
      *
    from table_columns
  `;return r+="\n",e.length>0?r+=`where schema in (${e.map(e=>`quote_ident('${e}')`).join(",")})`:r+=`where schema not in (${q.map(e=>`'${e}'`).join(",")})`,r}function k(e,t=[]){let n=I`
    with
      tables as (${`
SELECT
  c.oid :: int8 AS id,
  nc.nspname AS schema,
  c.relname AS name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS rls_forced,
  CASE
    WHEN c.relreplident = 'd' THEN 'DEFAULT'
    WHEN c.relreplident = 'i' THEN 'INDEX'
    WHEN c.relreplident = 'f' THEN 'FULL'
    ELSE 'NOTHING'
  END AS replica_identity,
  pg_total_relation_size(format('%I.%I', nc.nspname, c.relname)) :: int8 AS bytes,
  pg_size_pretty(
    pg_total_relation_size(format('%I.%I', nc.nspname, c.relname))
  ) AS size,
  pg_stat_get_live_tuples(c.oid) AS live_rows_estimate,
  pg_stat_get_dead_tuples(c.oid) AS dead_rows_estimate,
  obj_description(c.oid) AS comment,
  coalesce(pk.primary_keys, '[]') as primary_keys,
  coalesce(
    jsonb_agg(relationships) filter (where relationships is not null),
    '[]'
  ) as relationships
FROM
  pg_namespace nc
  JOIN pg_class c ON nc.oid = c.relnamespace
  left join (
    select
      table_id,
      jsonb_agg(_pk.*) as primary_keys
    from (
      select
        n.nspname as schema,
        c.relname as table_name,
        a.attname as name,
        c.oid :: int8 as table_id
      from
        pg_index i,
        pg_class c,
        pg_attribute a,
        pg_namespace n
      where
        i.indrelid = c.oid
        and c.relnamespace = n.oid
        and a.attrelid = c.oid
        and a.attnum = any (i.indkey)
        and i.indisprimary
    ) as _pk
    group by table_id
  ) as pk
  on pk.table_id = c.oid
  left join (
    select
      c.oid :: int8 as id,
      c.conname as constraint_name,
      nsa.nspname as source_schema,
      csa.relname as source_table_name,
      sa.attname as source_column_name,
      nta.nspname as target_table_schema,
      cta.relname as target_table_name,
      ta.attname as target_column_name
    from
      pg_constraint c
    join (
      pg_attribute sa
      join pg_class csa on sa.attrelid = csa.oid
      join pg_namespace nsa on csa.relnamespace = nsa.oid
    ) on sa.attrelid = c.conrelid and sa.attnum = any (c.conkey)
    join (
      pg_attribute ta
      join pg_class cta on ta.attrelid = cta.oid
      join pg_namespace nta on cta.relnamespace = nta.oid
    ) on ta.attrelid = c.confrelid and ta.attnum = any (c.confkey)
    where
      c.contype = 'f'
  ) as relationships
  on (relationships.source_schema = nc.nspname and relationships.source_table_name = c.relname)
  or (relationships.target_table_schema = nc.nspname and relationships.target_table_name = c.relname)
WHERE
  c.relkind IN ('r', 'p')
  AND NOT pg_is_other_temp_schema(nc.oid)
  AND c.relname = quote_ident('${e}')
  AND (
    pg_has_role(c.relowner, 'USAGE')
    OR has_table_privilege(
      c.oid,
      'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'
    )
    OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES')
  )
group by
  c.oid,
  c.relname,
  c.relrowsecurity,
  c.relforcerowsecurity,
  c.relreplident,
  nc.nspname,
  pk.primary_keys
`}),
      columns as (${D})
    select
      *,
      ${H("columns","columns.table_id = tables.id")}
    from tables
  `;return n+="\n",t.length>0?n+=`where schema in (${t.map(e=>`quote_ident('${e}')`).join(",")})`:n+=`where schema not in (${q.map(e=>`'${e}'`).join(",")})`,n}let H=(e,t)=>I`
    COALESCE(
      (
        SELECT
          array_agg(row_to_json(${e})) FILTER (WHERE ${t})
        FROM
          ${e}
      ),
      '{}'
    ) AS ${e}
  `;e.s(["listTableInfoSql",()=>k,"listTablesNameRowCountSql",()=>$],167731);let F=I`
  SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual,
    with_check
  FROM pg_policies
  WHERE schemaname = 'public'
  ORDER BY tablename, policyname;
`,U=I`
  SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual,
    with_check
  FROM pg_policies
  WHERE schemaname = 'storage' AND tablename = 'objects'
  ORDER BY policyname;
`,P=I`
  SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd,
    qual,
    with_check
  FROM pg_policies
  WHERE schemaname = 'realtime' AND tablename = 'messages'
  ORDER BY policyname;
`;I`
  SELECT
    c.oid :: int8 AS id,
    nc.nspname AS schema,
    c.relname AS name,
    c.relrowsecurity AS rls_enabled,
    pg_stat_get_live_tuples(c.oid) AS live_rows_estimate
  FROM
    pg_class c
    JOIN pg_namespace nc ON c.relnamespace = nc.oid
  WHERE
    nc.nspname = 'public'
    AND c.relkind IN ('r', 'p')
  ORDER BY c.relname;
`;let W=(0,y.getApiConfig)().getBaseUrl(),M=()=>{let e=(0,f.useProjectStore)(e=>e.project?.id),{selectedInstance:t}=(0,f.useSelectedCloudInstance)();return(0,m.useMemo)(()=>e?function(e){let{baseUrl:t="",Request:n=globalThis.Request,fetch:r=globalThis.fetch,querySerializer:m,bodySerializer:f,headers:y,requestInitExt:_,...g}={...e};_="object"==typeof a.default&&Number.parseInt(a.default?.versions?.node?.substring(0,2))>=18&&a.default.versions.undici?_:void 0,t=p(t);let E=[];async function h(e,a){var h,b;let S,A,R,N,w,{baseUrl:T,fetch:O=r,Request:j=n,headers:v,params:C={},parseAs:I="json",querySerializer:D,bodySerializer:L=f??u,body:q,...$}=a||{},k=t;T&&(k=p(T)??t);let H="function"==typeof m?m:c(m);D&&(H="function"==typeof D?D:c({..."object"==typeof m?m:{},...D}));let F=void 0===q?void 0:L(q,d(y,v,C.header)),U=d(void 0===F||F instanceof FormData?{}:{"Content-Type":"application/json"},y,v,C.header),P={redirect:"follow",...g,...$,body:F,headers:U},W=new n((h=e,b={baseUrl:k,params:C,querySerializer:H},S=`${b.baseUrl}${h}`,b.params?.path&&(S=function(e,t){let n=e;for(let r of e.match(o)??[]){let e=r.substring(1,r.length-1),a=!1,o="simple";if(e.endsWith("*")&&(a=!0,e=e.substring(0,e.length-1)),e.startsWith(".")?(o="label",e=e.substring(1)):e.startsWith(";")&&(o="matrix",e=e.substring(1)),!t||void 0===t[e]||null===t[e])continue;let c=t[e];if(Array.isArray(c)){n=n.replace(r,l(e,c,{style:o,explode:a}));continue}if("object"==typeof c){n=n.replace(r,s(e,c,{style:o,explode:a}));continue}if("matrix"===o){n=n.replace(r,`;${i(e,c)}`);continue}n=n.replace(r,"label"===o?`.${encodeURIComponent(c)}`:encodeURIComponent(c))}return n}(S,b.params.path)),(A=b.querySerializer(b.params.query??{})).startsWith("?")&&(A=A.substring(1)),A&&(S+=`?${A}`),S),P);for(let e in $)e in W||(W[e]=$[e]);if(E.length){for(let t of(R=Math.random().toString(36).slice(2,11),N=Object.freeze({baseUrl:k,fetch:O,parseAs:I,querySerializer:H,bodySerializer:L}),E))if(t&&"object"==typeof t&&"function"==typeof t.onRequest){let r=await t.onRequest({request:W,schemaPath:e,params:C,options:N,id:R});if(r)if(r instanceof n)W=r;else if(r instanceof Response){w=r;break}else throw Error("onRequest: must return new Request() or Response() when modifying the request")}}if(!w){try{w=await O(W,_)}catch(n){let t=n;if(E.length)for(let n=E.length-1;n>=0;n--){let r=E[n];if(r&&"object"==typeof r&&"function"==typeof r.onError){let n=await r.onError({request:W,error:t,schemaPath:e,params:C,options:N,id:R});if(n){if(n instanceof Response){t=void 0,w=n;break}if(n instanceof Error){t=n;continue}throw Error("onError: must return new Response() or instance of Error")}}}if(t)throw t}if(E.length)for(let t=E.length-1;t>=0;t--){let n=E[t];if(n&&"object"==typeof n&&"function"==typeof n.onResponse){let t=await n.onResponse({request:W,response:w,schemaPath:e,params:C,options:N,id:R});if(t){if(!(t instanceof Response))throw Error("onResponse: must return new Response() when modifying the response");w=t}}}}if(204===w.status||"HEAD"===W.method||"0"===w.headers.get("Content-Length"))return w.ok?{data:void 0,response:w}:{error:void 0,response:w};if(w.ok)return"stream"===I?{data:w.body,response:w}:{data:await w[I](),response:w};let M=await w.text();try{M=JSON.parse(M)}catch{}return{error:M,response:w}}return{request:(e,t,n)=>h(t,{...n,method:e.toUpperCase()}),GET:(e,t)=>h(e,{...t,method:"GET"}),PUT:(e,t)=>h(e,{...t,method:"PUT"}),POST:(e,t)=>h(e,{...t,method:"POST"}),DELETE:(e,t)=>h(e,{...t,method:"DELETE"}),OPTIONS:(e,t)=>h(e,{...t,method:"OPTIONS"}),HEAD:(e,t)=>h(e,{...t,method:"HEAD"}),PATCH:(e,t)=>h(e,{...t,method:"PATCH"}),TRACE:(e,t)=>h(e,{...t,method:"TRACE"}),use(...e){for(let t of e)if(t){if("object"!=typeof t||!("onRequest"in t||"onResponse"in t||"onError"in t))throw Error("Middleware must be an object with one of `onRequest()`, `onResponse() or `onError()`");E.push(t)}},eject(...e){for(let t of e){let e=E.indexOf(t);-1!==e&&E.splice(e,1)}}}}({baseUrl:`${W}/projects/${e}/cloud/db-proxy`,fetch:async e=>{let n=await E.tokenManager.getValidToken();if(!n)throw Error("No token available");let r=new URL(e.url);r.searchParams.set("env",t);let a=new Headers(e.headers);for(let[e,t]of(a.set("Authorization",`Bearer ${n}`),Object.entries((0,_.getApiEnvironmentHeaders)())))a.set(e,t);let o=null;return"GET"!==e.method&&"HEAD"!==e.method&&(o=await e.clone().text()),fetch(r.toString(),{method:e.method,headers:a,body:o})}}):null,[e,t])},x=async({projectRef:e,query:t,readOnly:n,dbClient:r,signal:a})=>{let{data:o,error:i}=await r.POST("/v1/projects/{ref}/database/query",{params:{path:{ref:e}},body:{query:t,read_only:n},signal:a});if(i)throw i;return o},z=async(e,t,n)=>{let r=`SELECT COUNT(*) AS total FROM ${t}`,a=await x({projectRef:e,query:r,readOnly:!0,dbClient:n});return a?.[0]?.total??0},G=async(e,t)=>{let{data:n,error:r}=await t.GET("/v1/projects/{ref}/functions",{params:{path:{ref:e}}});if(r)throw r;return n??[]},K=async(e,t)=>x({projectRef:e,query:F,readOnly:!0,dbClient:t}),B=async(e,t)=>x({projectRef:e,query:U,readOnly:!0,dbClient:t}),J=async(e,t)=>x({projectRef:e,query:P,readOnly:!0,dbClient:t}),Y=async({projectRef:e,dbClient:t})=>{let{data:n,error:r}=await t.POST("/v1/projects/{ref}/restore",{params:{path:{ref:e}}});if(r)throw r;return n};e.s(["useGetRLSPolicies",0,e=>{let t=M(),{selectedInstance:r}=(0,f.useSelectedCloudInstance)();return(0,n.useQuery)({queryKey:h.cloudKeys.database.rlsPolicies(e,r),queryFn:()=>K(e,t),enabled:!!e&&!!t,retry:!1})},"useGetRealtimePolicies",0,e=>{let t=M(),{selectedInstance:r}=(0,f.useSelectedCloudInstance)();return(0,n.useQuery)({queryKey:h.cloudKeys.database.realtimePolicies(e,r),queryFn:()=>J(e,t),enabled:!!e&&!!t,retry:!1})},"useGetStoragePolicies",0,e=>{let t=M(),{selectedInstance:r}=(0,f.useSelectedCloudInstance)();return(0,n.useQuery)({queryKey:h.cloudKeys.database.storagePolicies(e,r),queryFn:()=>B(e,t),enabled:!!e&&!!t,retry:!1})},"useGetTableCount",0,(e,t)=>{let r=M(),{selectedInstance:a}=(0,f.useSelectedCloudInstance)();return(0,n.useQuery)({queryKey:h.cloudKeys.database.tableCount(e,a,t),queryFn:()=>z(e,t,r),enabled:!!e&&!!t&&!!r,retry:!1})},"useGetUserCountsByDay",0,(e,t)=>{let r=M(),{selectedInstance:a}=(0,f.useSelectedCloudInstance)();return(0,n.useQuery)({queryKey:h.cloudKeys.database.userCounts(e,a,t),queryFn:()=>(({projectRef:e,days:t,dbClient:n})=>x({projectRef:e,query:`
    WITH days_series AS (
      SELECT generate_series(
        date_trunc('day', now() - interval '${Number(t)-1} days'),
        date_trunc('day', now()),
        '1 day'::interval
      )::date AS date
    )
    SELECT
      d.date,
      COALESCE(u.users, 0)::int as users
    FROM
      days_series d
    LEFT JOIN (
      SELECT
        date_trunc('day', created_at AT TIME ZONE 'UTC')::date as date,
        count(id) as users
      FROM
        auth.users
      GROUP BY 1
    ) u ON d.date = u.date
    ORDER BY
      d.date ASC;
  `,readOnly:!0,dbClient:n}))({projectRef:e,days:t,dbClient:r}),enabled:!!e&&!!r,retry:!1})},"useListFunctions",0,e=>{let t=M(),{selectedInstance:r}=(0,f.useSelectedCloudInstance)();return(0,n.useQuery)({queryKey:h.cloudKeys.database.functions(e,r),queryFn:()=>G(e,t),enabled:!!e&&!!t,retry:!1,refetchOnMount:"always"})},"useListTables",0,(e,t)=>{let r=M(),{selectedInstance:a}=(0,f.useSelectedCloudInstance)();return(0,n.useQuery)({queryKey:h.cloudKeys.database.tables(e,a,t),queryFn:()=>(({projectRef:e,schemas:t,dbClient:n})=>x({projectRef:e,query:$(t),readOnly:!0,dbClient:n}))({projectRef:e,schemas:t,dbClient:r}),enabled:!!e&&!!r})},"useRestoreProject",0,()=>{let e=(0,r.useQueryClient)(),n=M(),a=(0,f.useProjectStore)(e=>e.project?.id),{selectedInstance:o}=(0,f.useSelectedCloudInstance)();return(0,t.useMutation)({mutationFn:({projectRef:e})=>{if(!n)throw Error("Database client not available");return Y({projectRef:e,dbClient:n})},onSuccess:()=>{e.invalidateQueries({queryKey:h.cloudKeys.status(a,o)})},onError:e=>{(0,g.showErrorToast)(e)},retry:3,retryDelay:e=>Math.min(2e3*2**e,1e4)})},"useRunQuery",0,()=>{let e=M();return(0,t.useMutation)({mutationFn:({projectRef:t,query:n,readOnly:r,signal:a})=>{if(!e)throw Error("Database client not available");return x({projectRef:t,query:n,readOnly:r,dbClient:e,signal:a})},onError:e=>{e instanceof DOMException&&"AbortError"===e.name||(0,g.showErrorToast)(e)}})}],974982)},84596,e=>{"use strict";var t=e.i(48105),n=e.i(616337),r=e.i(669285),a=e.i(974982),o=e.i(446129);e.s(["useLovableCloudPausedWithRestore",0,({project:e,projectRef:i})=>{let[s,l]=(0,n.default)(`hasTriggeredRestore-${e?.id}`,{defaultValue:{hasTriggered:!1,triggeredAt:0}}),c=(0,a.useRestoreProject)(),u=(0,t.useRef)([]),{hasTriggered:d,triggeredAt:p}=s,m=Date.now()-p,f=d&&m>6e5;(0,t.useEffect)(()=>{f&&l({hasTriggered:!1,triggeredAt:0})},[f,l]);let y=(0,o.useProjectHasLovableCloudEnabled)(e),{data:_,dataUpdatedAt:g,isLoading:E,error:h}=(0,r.useGetStatus)({refetchIntervalWhenTransitioning:1e3,refetchInterval:d?1e3:3e4}),b=_?.status,S=e?.cloud_credit_ran_out===!0;(0,t.useEffect)(()=>{"INACTIVE"!==b||c.isPending||d||!i||S||(l({hasTriggered:!0,triggeredAt:Date.now()}),c.mutate({projectRef:i}))},[b,i,c,d,l,S]),(0,t.useEffect)(()=>{"RESTORING"!==b||d||l({hasTriggered:!0,triggeredAt:Date.now()})},[b,d,l]),(0,t.useEffect)(()=>{b&&(u.current.push(b),u.current.length>10&&(u.current=u.current.slice(-10)))},[b,g]);let A=u.current.length>=10,R=u.current.every(e=>"OK"===e),N=A&&R;(0,t.useEffect)(()=>{N&&(l({hasTriggered:!1,triggeredAt:0}),u.current=[])},[N,l]);let w="PAUSING"===b,T=d&&!N,O=!w&&!T&&!S,j=(0,t.useCallback)(()=>{i&&O&&(l({hasTriggered:!0,triggeredAt:Date.now()}),c.mutate({projectRef:i}))},[i,O,l,c]);return{isRestoring:T,isPaused:"INACTIVE"===b||"PAUSING"===b,isHealthy:"OK"===b,isPausing:w,canTriggerRestore:O,hasError:h,isLovableCloudProject:y,isBackendStatusLoading:E,triggerRestore:j}}])},665136,e=>{"use strict";var t=e.i(69235);e.i(767460);var n=e.i(504037);e.s(["useAIGatewayData",0,({projectId:e,enabled:r=!0})=>(0,t.useQuery)({queryKey:["projects",e,"integrations","ai_gateway"],queryFn:async()=>(0,n.getGoApi)().get(`/projects/${e}/integrations/ai_gateway`),enabled:r&&!!e})])}]);

//# debugId=c329c6fb-555d-0d18-f705-9473567eaefb
//# sourceMappingURL=11abc2bba0fc89a2.js.map